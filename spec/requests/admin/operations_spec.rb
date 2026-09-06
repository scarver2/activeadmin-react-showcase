# spec/requests/admin/operations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin operations" do
  let(:admin_user) { create(:admin_user) }

  before { sign_in admin_user }

  it "creates and enqueues an authorized bounded operation" do
    expect do
      post admin_operations_path, params: { kind: "successful_demo" }, headers: { "Idempotency-Key" => "create-1" }, as: :json
    end.to have_enqueued_job(DemoOperationJob).and change(Operation, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("state" => "queued", "sequence" => 1)
  end

  it "enqueues durable work even when Cable broadcast delivery fails" do
    allow(ActionCable.server).to receive(:broadcast).and_raise("Cable unavailable")
    allow(Rails.logger).to receive(:error)

    expect do
      post admin_operations_path, params: { kind: "successful_demo" },
                                  headers: { "Idempotency-Key" => "create-without-cable" }, as: :json
    end.to have_enqueued_job(DemoOperationJob).and change(Operation, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(Rails.logger).to have_received(:error).with(/Cable broadcast failed/)
  end

  it "rejects unsupported work" do
    post admin_operations_path, params: { kind: "arbitrary_command" }, headers: { "Idempotency-Key" => "invalid-1" }, as: :json

    expect(response).to have_http_status(:bad_request)
  end

  it "defaults to a successful demo and redirects the server form" do
    post admin_operations_path, params: { idempotency_key: "html-1" }

    expect(response).to redirect_to(/\/admin\/live_jobs\?operation_id=/)
    expect(Operation.last.kind).to eq("successful_demo")
  end

  it "records cancellation as an authenticated command" do
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")

    post cancel_admin_operation_path(operation.public_id), params: { operation_id: operation.public_id }, as: :json

    expect(response).to have_http_status(:ok)
    expect(operation.reload).to have_attributes(state: "cancelled", cancel_requested_at: be_present)
  end

  it "records cancellation intent while a worker is running" do
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")
    Operations::Transition.call(operation:, state: "running", progress: 10, message: "Working")

    post cancel_admin_operation_path(operation.public_id), params: { operation_id: operation.public_id }, as: :json

    expect(operation.reload).to have_attributes(state: "running", message: "Cancellation requested", cancel_requested_at: be_present)
  end

  it "records a terminal cancellation command only once" do
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")
    operation.update!(state: "completed", progress: 100)

    post cancel_admin_operation_path(operation.public_id), as: :json
    expect(operation.reload.cancel_idempotency_key).to eq("cancel:#{operation.public_id}")

    expect do
      post cancel_admin_operation_path(operation.public_id), as: :json
    end.not_to change { operation.reload.updated_at }

    expect(operation.events.where(state: "cancelled")).to be_empty
  end

  it "retries a terminal operation as a new persistent operation" do
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")
    operation.update!(state: "failed", error: "Expected")

    expect do
      post retry_admin_operation_path(operation.public_id), headers: { "Idempotency-Key" => "retry-1" }, as: :json
    end.to change(Operation, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("retry_of" => operation.public_id, "state" => "queued")
  end

  it "refuses to retry active work" do
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")

    post retry_admin_operation_path(operation.public_id), headers: { "Idempotency-Key" => "retry-active" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns current authorized operation state" do
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")

    get admin_operation_path(operation.public_id), as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("operation_id" => operation.public_id)
  end

  it "does not expose operations owned by another administrator" do
    operation = Operations::Create.call(admin_user: create(:admin_user), kind: "successful_demo", request_idempotency_key: "request-1")

    get admin_operation_path(operation.public_id), as: :json

    expect(response).to have_http_status(:not_found)
  end

  it "requires an explicit idempotency key for create and retry" do
    post admin_operations_path, params: { kind: "successful_demo" }, as: :json
    expect(response).to have_http_status(:bad_request)

    sign_in admin_user
    operation = Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-key")
    operation.update!(state: "failed")
    post retry_admin_operation_path(operation.public_id), as: :json
    expect(response).to have_http_status(:bad_request)
  end

  it "deduplicates repeated create, cancel, and retry commands" do
    2.times do
      post admin_operations_path, params: { kind: "successful_demo" }, headers: { "Idempotency-Key" => "create-once" }, as: :json
    end
    operation = Operation.find_by!(request_idempotency_key: "create-once")
    expect(Operation.where(request_idempotency_key: "create-once").count).to eq(1)

    2.times { post cancel_admin_operation_path(operation.public_id), as: :json }
    expect(operation.events.where(state: "cancelled").count).to eq(1)

    2.times do
      post retry_admin_operation_path(operation.public_id), headers: { "Idempotency-Key" => "retry-once" }, as: :json
    end
    expect(Operation.where(request_idempotency_key: "retry-once").count).to eq(1)
  end
end
