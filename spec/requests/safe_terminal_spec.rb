# spec/requests/safe_terminal_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Safe terminal" do
  let(:admin_user) { create(:admin_user) }

  before do
    allow(SafeTerminalDemoJob).to receive(:perform_later)
    sign_in admin_user
  end

  it "renders the page contract and no-JavaScript fallback" do
    execution = create(:terminal_execution, admin_user:)
    create(:terminal_output, terminal_execution: execution, text: "Durable transcript")

    get admin_safe_terminal_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("A terminal-shaped interface, never a shell")
    expect(response.body).to include("Durable transcript", "Run safe command", "Ruby", "JavaScript", "Architecture")
  end

  it "creates one allowlisted execution with an idempotency key" do
    expect {
      post admin_terminal_executions_path,
        params: { command_key: "showcase:status" },
        headers: { "Accept" => "application/json", "Idempotency-Key" => "request-1" }
    }.to change(admin_user.terminal_executions, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("commandKey" => "showcase:status", "sequence" => 1, "state" => "queued")
    expect(SafeTerminalDemoJob).to have_received(:perform_later).once
  end

  it "supports the ordinary Rails form" do
    post admin_terminal_executions_path,
      params: { command_key: "showcase:status", idempotency_key: "form-request" }

    expect(response).to redirect_to(admin_safe_terminal_path)
    follow_redirect!
    expect(response.body).to include("Allowlisted demo command queued")
  end

  it "rejects arbitrary commands, missing commands, and missing idempotency" do
    post admin_terminal_executions_path,
      params: { command_key: "showcase:status; whoami" },
      headers: { "Accept" => "application/json", "Idempotency-Key" => "injection" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("error")).to eq("Command is not allowlisted")

    post admin_terminal_executions_path,
      params: {}, headers: { "Accept" => "application/json", "Idempotency-Key" => "missing" }
    expect(response).to have_http_status(:unprocessable_content)

    post admin_terminal_executions_path,
      params: { command_key: "showcase:status" }, headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:bad_request)
  end

  it "cancels only the current administrator's execution" do
    own = create(:terminal_execution, admin_user:)
    other = create(:terminal_execution)

    post cancel_admin_terminal_execution_path(own.public_id), headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("state")).to eq("cancelled")

    post cancel_admin_terminal_execution_path(other.public_id), headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:not_found)
  end

  it "requires an authenticated administrator" do
    sign_out admin_user

    get admin_safe_terminal_path
    expect(response).to redirect_to(new_admin_user_session_path)

    post admin_terminal_executions_path,
      params: { command_key: "showcase:status" },
      headers: { "Accept" => "application/json", "Idempotency-Key" => "unauthorized" }
    expect(response).to have_http_status(:unauthorized)
  end
end
