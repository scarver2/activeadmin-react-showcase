# spec/requests/relationship_explorer_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Relationship explorer" do
  let(:admin) { create(:admin_user) }
  let(:account) { create(:account, name: "Bluebonnet Logistics") }

  describe "GET /admin/relationship_explorer" do
    before { sign_in admin }

    it "renders the page contract and useful server fallback" do
      create(:contact, account:, first_name: "Marisol", last_name: "Vega")

      get admin_relationship_explorer_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-react-component="RelationshipExplorer"')
      expect(response.body).to include("Account and contact relationships remain navigable without JavaScript")
      expect(response.body).to include("Bluebonnet Logistics", "Marisol Vega", "Browse all Rails-owned contacts")
      expect(response.body).to include("Demo", "Ruby", "JavaScript", "Architecture")
    end
  end

  describe "GET /admin/relationship-explorer/accounts" do
    it "rejects unauthenticated requests" do
      get admin_relationship_explorer_accounts_path, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns an authenticated bounded relationship result" do
      sign_in admin
      create(:contact, account:, first_name: "Marisol", last_name: "Vega")

      get admin_relationship_explorer_accounts_path,
          params: { query: "Vega", relationship_role: "Operations lead" },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("total" => 1, "truncated" => false)
      expect(response.parsed_body.dig("selectedAccount", "contacts").first).to include(
        "fullName" => "Marisol Vega",
        "relationshipRole" => "Operations lead"
      )
    end

    it "returns an actionable error for unsupported controls" do
      sign_in admin

      get admin_relationship_explorer_accounts_path, params: { region: "Worldwide" }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "region is not supported")
    end
  end
end
