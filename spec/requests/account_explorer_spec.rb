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
      expect(response.body).to include("Accounts available without JavaScript remain canonical Rails pages")
      expect(response.body).to include("Bluebonnet Logistics", admin_account_path(Account.find_by!(name: "Bluebonnet Logistics")))
      expect(response.body).to include("Open the full Accounts index")
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

  describe "GET /admin/accounts/:id/inspector" do
    let(:account) { create(:account, name: "Bluebonnet Logistics") }

    it "requires an authenticated ActiveAdmin session" do
      get inspector_admin_account_path(account, format: :json)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("error" => "You need to sign in or sign up before continuing.")
    end

    it "returns Rails-authorized context and canonical destinations" do
      sign_in admin
      create(:contact, account:)
      create(:daily_metric, account:, active_users: 42, revenue_cents: 125_000)

      get inspector_admin_account_path(account, format: :json)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "account" => hash_including("name" => "Bluebonnet Logistics"),
        "canonicalHref" => admin_account_path(account),
        "metrics" => hash_including("activeUsers" => 42),
        "relationships" => { "contacts" => 1, "observations" => 1 }
      )
      expect(response.parsed_body.fetch("actions")).to include(
        { "href" => admin_account_path(account), "label" => "View full account" }
      )
    end

    it "returns not found when a stale inspector URL targets a deleted record" do
      sign_in admin
      stale_id = account.id
      account.destroy!

      get inspector_admin_account_path(stale_id, format: :json)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/accounts" do
    it "enhances the dense index with the same inspector and a canonical no-JavaScript fallback" do
      account = create(:account, name: "Bluebonnet Logistics")
      sign_in admin

      get admin_accounts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-react-component="AccountInspectorLauncher"')
      expect(response.body).to include(
        inspector_admin_account_path(account, format: :json),
        "Open Bluebonnet Logistics",
        admin_account_path(account)
      )
    end
  end
end
