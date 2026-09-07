# spec/requests/admin_analytics_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin analytics" do
  let(:admin) { create(:admin_user) }
  let(:account) { create(:account) }

  describe "GET /admin/analytics" do
    before { sign_in admin }

    it "renders guidance, the mount contract, and a meaningful server fallback" do
      create(:daily_metric, account:, active_users: 12, revenue_cents: 34_500, recorded_on: Date.current)

      get admin_analytics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-react-component="AnalyticsDashboard"')
      expect(response.body).to include("12 active-user observations")
      expect(response.body).to include("Demo", "Ruby", "JavaScript", "Architecture")
    end
  end

  describe "GET /admin/analytics/data" do
    it "rejects an unauthenticated request" do
      get admin_analytics_data_path, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the authenticated response contract for an ISO 8601 range" do
      sign_in admin
      create(:daily_metric, account:, active_users: 12, recorded_on: Date.new(2026, 9, 1))

      get admin_analytics_data_path,
          params: { start_date: "2026-09-01", end_date: "2026-09-01" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "range" => { "endDate" => "2026-09-01", "startDate" => "2026-09-01" },
        "series" => [ hash_including("activeUsers" => 12, "date" => "2026-09-01") ]
      )
    end

    it "returns an actionable validation error for malformed dates" do
      sign_in admin

      get admin_analytics_data_path, params: { start_date: "tomorrowish" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "start_date must be an ISO 8601 date")
    end

    it "treats structured date input as malformed instead of raising" do
      sign_in admin

      get admin_analytics_data_path, params: { end_date: [ "2026-09-01" ] }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "end_date must be an ISO 8601 date")
    end

    it "bounds the requested date range" do
      sign_in admin

      get admin_analytics_data_path,
          params: { start_date: "2026-01-01", end_date: "2026-06-01" },
          as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "date range must not exceed 90 days")
    end
  end
end
