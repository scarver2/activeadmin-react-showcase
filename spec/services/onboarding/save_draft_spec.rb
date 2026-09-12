# spec/services/onboarding/save_draft_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Onboarding::SaveDraft do
  it "persists an authorized transition" do
    draft = create(:onboarding_draft)
    described_class.call(admin_user: draft.admin_user, draft:, attributes: { current_step: 2 }, expected_lock_version: 0)
    expect(draft.reload.current_step).to eq(2)
  end

  it "rejects stale and cross-owner writes" do
    draft = create(:onboarding_draft)
    expect { described_class.call(admin_user: draft.admin_user, draft:, attributes: {}, expected_lock_version: 9) }.to raise_error(described_class::StaleWrite)
    expect { described_class.call(admin_user: create(:admin_user), draft:, attributes: {}, expected_lock_version: 0) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "submits through Rails validation" do
    draft = create(:onboarding_draft, current_step: 3)
    described_class.call(admin_user: draft.admin_user, draft:, attributes: {}, expected_lock_version: 0, submit: true)
    expect(draft).to be_submitted
    expect(draft.submitted_at).to be_present
  end
end
