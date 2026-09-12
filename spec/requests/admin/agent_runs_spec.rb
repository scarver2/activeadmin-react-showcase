# spec/requests/admin/agent_runs_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin agent runs" do
  let(:admin_user) { create(:admin_user) }

  before { sign_in admin_user }

  it "creates a bounded run and supports the server-rendered form" do
    expect do
      post admin_agent_runs_path, params: { prompt: "Inspect synthetic accounts" }
    end.to change(AgentRun, :count).by(1).and have_enqueued_job(DemoAgentJob)
    expect(response).to redirect_to(/\/admin\/agent_console\?run_id=/)
  end

  it "returns current state and records cancellation intent" do
    run = create(:agent_run, admin_user:)
    get admin_agent_run_path(run.public_id), as: :json
    expect(response.parsed_body).to include("id" => run.public_id, "state" => "queued")

    post cancel_admin_agent_run_path(run.public_id), as: :json
    expect(response).to have_http_status(:ok)
    expect(run.reload.cancel_requested_at).to be_present
  end

  it "does not expose another administrator's run" do
    run = create(:agent_run)
    get admin_agent_run_path(run.public_id), as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "rejects an empty or oversized prompt" do
    post admin_agent_runs_path, params: { prompt: "" }, as: :json
    expect(response).to have_http_status(:bad_request)

    sign_in admin_user
    post admin_agent_runs_path, params: { prompt: "x" * 501 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end
end
