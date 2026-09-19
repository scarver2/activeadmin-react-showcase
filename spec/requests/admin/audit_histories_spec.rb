# spec/requests/admin/audit_histories_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin audit histories" do
  it "returns an authorized restoration preview" do
    admin = create(:admin_user)
    profile = AuditHistory::Seed.call(admin_user: admin)
    sign_in admin
    get admin_audit_profile_history_path(profile), params: { version_id: profile.versions.second.id }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("preview")).to include("attributes")
  end

  it "rejects cross-owner and unknown version requests" do
    admin = create(:admin_user)
    sign_in admin
    profile = AuditHistory::Seed.call(admin_user: create(:admin_user))
    get admin_audit_profile_history_path(profile), params: { version_id: profile.versions.first.id }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end
end
