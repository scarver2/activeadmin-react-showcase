# spec/requests/admin/inline_account_fields_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin inline account fields" do
  let(:admin_user) { create(:admin_user) }
  let(:account) { create(:account, status: "active") }

  it "requires authentication" do
    patch admin_inline_account_field_path(account), params: { field: "status", lock_version: 0, value: "trial" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "persists an allowlisted field and returns canonical state" do
    sign_in admin_user
    patch admin_inline_account_field_path(account), params: { field: "status", lock_version: account.lock_version, value: "trial" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("status" => "trial", "lockVersion" => 1)
  end

  it "rejects unauthorized fields, record-specific restrictions, invalid values, and missing parameters" do
    sign_in admin_user
    patch admin_inline_account_field_path(account), params: { field: "plan", lock_version: 0, value: "Starter" }, as: :json
    expect(response).to have_http_status(:forbidden)
    account.update!(status: "trial")
    patch admin_inline_account_field_path(account), params: { field: "region", lock_version: account.lock_version, value: "West" }, as: :json
    expect(response).to have_http_status(:forbidden)
    patch admin_inline_account_field_path(account), params: { field: "status", lock_version: account.lock_version, value: "invalid" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_inline_account_field_path(account), params: { field: "status" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns canonical state on a stale lock" do
    sign_in admin_user
    stale_lock = account.lock_version
    account.update!(region: "East")
    patch admin_inline_account_field_path(account), params: { field: "region", lock_version: stale_lock, value: "West" }, as: :json
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("account", "region")).to eq("East")
  end
end
