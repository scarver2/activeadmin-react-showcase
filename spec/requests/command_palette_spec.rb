# spec/requests/command_palette_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Command palette" do
  let(:admin) { create(:admin_user) }

  describe "GET /admin/command_palette" do
    before { sign_in admin }

    it "renders the page contract and an ordinary Rails search fallback" do
      account = create(:account, name: "Bluebonnet Logistics")

      get admin_command_palette_path, params: { q: "blue" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.css('[data-react-component="CommandPalette"]').size).to eq(1)
      expect(response.body).to include("Search remains available as an ordinary authenticated Rails form")
      expect(response.body).to include(admin_account_path(account), "Account: Bluebonnet Logistics")
      expect(response.body).to include("Demo", "Ruby", "JavaScript", "Architecture")
    end

    it "renders an empty fallback state" do
      get admin_command_palette_path, params: { q: "missing" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No searchable records match")
    end

    it "renders a bounded-input error instead of executing an invalid fallback query" do
      get admin_command_palette_path, params: { q: "x" * 81 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("query must not exceed 80 characters")
    end
  end

  describe "GET /admin/global-search" do
    it "rejects unauthenticated requests" do
      get admin_global_search_path, params: { query: "blue" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only authenticated, server-ranked navigation contracts" do
      sign_in admin
      account = create(:account, name: "Bluebonnet Logistics")
      create(:account, name: "Unrelated Account")

      get admin_global_search_path, params: { query: "blue" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("query" => "blue")
      expect(response.parsed_body.fetch("results")).to contain_exactly(
        include("id" => "account-#{account.id}", "kind" => "Account", "url" => admin_account_path(account))
      )
    end

    it "returns an actionable error for malformed input" do
      sign_in admin

      get admin_global_search_path, params: { query: "x" * 81 }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "query must not exceed 80 characters")
    end
  end
end
