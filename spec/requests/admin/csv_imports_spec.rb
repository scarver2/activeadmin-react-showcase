# spec/requests/admin/csv_imports_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin CSV imports" do
  let(:admin_user) { create(:admin_user) }
  let(:source) { fixture_file_upload("contacts.csv", "text/csv") }
  let(:mappings) { { first_name: "first_name", last_name: "last_name", email: "email", account: "account" } }

  it "requires authentication" do
    post admin_csv_import_workflow_imports_path, params: { source: }, headers: { "ACCEPT" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "uploads, previews, recovers, and confirms an owned import" do
    sign_in admin_user
    post admin_csv_import_workflow_imports_path, params: { source: }, headers: { "ACCEPT" => "application/json" }
    expect(response).to have_http_status(:created)
    token = response.parsed_body.fetch("token")
    expect(response.parsed_body.dig("preview", "rowCount")).to eq(2)
    get admin_csv_import_workflow_import_path(token), as: :json
    expect(response.parsed_body.dig("preview", "headers")).to include("email")
    post confirm_admin_csv_import_workflow_import_path(token), params: { mappings: }, as: :json
    expect(response.parsed_body.fetch("status")).to eq("queued")
  end

  it "rejects missing files, invalid mappings, repeated confirmation, and foreign access" do
    sign_in admin_user
    post admin_csv_import_workflow_imports_path, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    csv_import = CsvImports::Create.call(admin_user:, source:)
    post confirm_admin_csv_import_workflow_import_path(csv_import.token), params: { mappings: {} }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    CsvImports::Confirm.call(csv_import:, mappings:)
    post confirm_admin_csv_import_workflow_import_path(csv_import.token), params: { mappings: }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    sign_in create(:admin_user)
    get admin_csv_import_workflow_import_path(csv_import.token), as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "supports HTML upload and confirmation fallbacks" do
    sign_in admin_user
    post admin_csv_import_workflow_imports_path, params: { source: }
    csv_import = admin_user.csv_imports.last
    expect(response).to redirect_to("/admin/csv_import_workflow?token=#{csv_import.token}")
    post confirm_admin_csv_import_workflow_import_path(csv_import.token), params: { mappings: }
    expect(response).to redirect_to("/admin/csv_import_workflow?token=#{csv_import.token}")
  end
end
