# spec/requests/account_explorer_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account data explorer" do
  let(:admin) { create(:admin_user) }

  describe "GET /admin/data_explorer" do
    before { sign_in admin }

    it "renders the page contract and meaningful server fallback" do
      create(:account, name: "Bluebonnet Logistics")

      get admin_data_explorer_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-react-component="AccountExplorer"')
      expect(response.body).to include("Accounts available without JavaScript: Bluebonnet Logistics")
      expect(response.body).to include("Demo", "Ruby", "JavaScript", "Architecture")
    end
  end

  describe "GET /admin/data-explorer/accounts" do
    it "rejects unauthenticated requests" do
      get admin_data_explorer_accounts_path, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns an authenticated bounded result" do
      sign_in admin
      create(:account, name: "Bluebonnet Logistics")

      get admin_data_explorer_accounts_path, params: { query: "blue", sort: "name" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("page" => 1, "perPage" => 5, "total" => 1)
      expect(response.parsed_body.fetch("rows").first).to include("name" => "Bluebonnet Logistics")
    end

    it "returns an actionable error for unsupported controls" do
      sign_in admin

      get admin_data_explorer_accounts_path, params: { sort: "DROP TABLE accounts" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "sort is not supported")
    end
  end
end
