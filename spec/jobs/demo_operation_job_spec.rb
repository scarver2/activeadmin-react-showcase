# spec/jobs/demo_operation_job_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe DemoOperationJob, database_cleaner: :truncation do
  around do |example|
    ClimateControl.modify(SHOWCASE_OPERATION_STEP_DELAY: "0") { example.run }
  end

  def operation_for(kind: "successful_demo")
    Operations::Create.call(admin_user: create(:admin_user), kind:, request_idempotency_key: SecureRandom.uuid)
  end

  it "performs bounded progress and completes persistently" do
    operation = operation_for

    described_class.perform_now(operation.id)

    expect(operation.reload).to have_attributes(state: "completed", progress: 100, result: /Six account/)
    expect(operation.events.pluck(:sequence)).to eq((1..7).to_a)
  end

  it "persists an expected failure as a terminal event" do
    operation = operation_for(kind: "failing_demo")

    described_class.perform_now(operation.id)

    expect(operation.reload).to have_attributes(state: "failed", error: /Demonstration failure/)
  end

  it "completes durable work when every Cable delivery fails" do
    operation = operation_for
    allow(ActionCable.server).to receive(:broadcast).and_raise("Cable unavailable")
    allow(Rails.logger).to receive(:error)

    expect { described_class.perform_now(operation.id) }.not_to raise_error

    expect(operation.reload).to have_attributes(state: "completed", progress: 100)
    expect(Rails.logger).to have_received(:error).at_least(:once)
  end

  it "honors a persisted cancellation request" do
    operation = operation_for
    operation.update!(cancel_requested_at: Time.current)

    described_class.perform_now(operation.id)

    expect(operation.reload).to have_attributes(state: "cancelled")
  end

  it "ignores missing and terminal operations" do
    operation = operation_for
    operation.update!(state: "completed", progress: 100)

    expect { described_class.perform_now(-1) }.not_to raise_error
    expect { described_class.perform_now(operation.id) }.not_to change { operation.events.count }
  end

  it "persists unexpected failures and lets Solid Queue retain the failure" do
    operation = operation_for
    allow_any_instance_of(described_class).to receive(:pause).and_raise("unexpected")

    expect { described_class.perform_now(operation.id) }.to raise_error("unexpected")
    expect(operation.reload).to have_attributes(state: "failed", error: "unexpected")
  end

  it "resumes from persisted progress when the same Solid Queue job is redelivered" do
    operation = operation_for
    operation.update!(progress: 45, state: "running")
    job = described_class.new(operation.id)
    job.job_id = "delivery-1"

    job.perform(operation.id)

    expect(operation.reload).to have_attributes(state: "completed", progress: 100)
    expect(operation.events.where(progress: [ 5, 20, 45 ])).to be_empty
  end

  it "rejects a concurrent duplicate delivery while an SQLite-backed claim is live" do
    operation = operation_for
    Operations::Claim.call(operation:, token: "execution-1")
    duplicate = described_class.new(operation.id)
    duplicate.job_id = "delivery-2"

    expect { duplicate.perform(operation.id) }.to raise_error(Operations::Claim::Busy)
    expect(operation.reload.progress).to eq(0)
  end

  it "fences overlapping executions with the same serialized Solid Queue job id" do
    operation = operation_for
    entered_step = Queue.new
    release_step = Queue.new
    first_pause = true
    allow_any_instance_of(described_class).to receive(:pause) do
      next unless first_pause

      first_pause = false
      entered_step << true
      release_step.pop
    end
    original = described_class.new(operation.id)
    duplicate = described_class.new(operation.id)
    original.job_id = duplicate.job_id = "same-serialized-job"
    original_error = Queue.new
    original_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection { original.perform(operation.id) }
    rescue StandardError => e
      original_error << e
    end
    entered_step.pop

    expect { duplicate.perform(operation.id) }.to raise_error(Operations::Claim::Busy)
    release_step << true
    original_thread.join

    expect(original_error).to be_empty
    expect(operation.reload.state).to eq("completed")
    expect(operation.events.pluck(:sequence)).to eq((1..7).to_a)
  end
end
