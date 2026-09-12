# spec/models/onboarding_draft_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnboardingDraft do
  it "requires step fields only when they become authoritative" do
    draft = build(:onboarding_draft, company_name: "", contact_email: "", current_step: 1)
    expect(draft).to be_valid
    draft.current_step = 2
    expect(draft).not_to be_valid
  end

  it "requires regulated compliance details on submission" do
    draft = build(:onboarding_draft, account_kind: "regulated", compliance_contact: "", status: "submitted")
    expect(draft).not_to be_valid
  end
end
