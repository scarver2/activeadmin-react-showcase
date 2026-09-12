# spec/requests/admin/onboarding_drafts_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin onboarding drafts" do
  let(:admin) { create(:admin_user) }
  let(:draft) { create(:onboarding_draft, admin_user: admin) }

  before { sign_in admin }

  it "updates the signed-in administrator's draft" do
    patch admin_onboarding_draft_path(draft), params: { company_name: "Updated", current_step: 2, lock_version: 0 }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("draft", "company_name")).to eq("Updated")
  end

  it "returns validation and stale errors" do
    patch admin_onboarding_draft_path(draft), params: { company_name: "", current_step: 2, lock_version: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_onboarding_draft_path(draft), params: { current_step: 1, lock_version: 99 }, as: :json
    expect(response).to have_http_status(:conflict)
  end

  it "does not expose another administrator's draft" do
    patch admin_onboarding_draft_path(create(:onboarding_draft)), params: { lock_version: 0 }, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "accepts the ordinary ActiveAdmin form parameter shape" do
    patch admin_onboarding_draft_path(draft), params: { onboarding_draft: { company_name: "Fallback", current_step: 2 }, lock_version: 0 }
    expect(response).to redirect_to(admin_onboarding_wizard_path)
    expect(draft.reload.company_name).to eq("Fallback")
  end
end
