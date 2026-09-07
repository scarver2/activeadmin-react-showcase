# spec/requests/live_jobs_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Live Jobs page" do
  let(:admin_user) { create(:admin_user) }

  it "requires authentication" do
    get "/admin/live_jobs"

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "renders guidance and meaningful server fallback" do
    sign_in admin_user
    Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1")

    get "/admin/live_jobs"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Persistent work, live transport")
    expect(response.body).to include("Start bounded demo operation")
    expect(response.body).to include("Waiting for a worker")
  end
end
