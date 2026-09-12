# spec/services/audit_history/seed_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHistory::Seed do
  it "creates deterministic attributed history idempotently" do
    admin = create(:admin_user)
    profile = described_class.call(admin_user: admin)
    expect(profile.versions.count).to eq(3)
    expect(profile.versions.pluck(:whodunnit)).to include("Avery Admin", "Morgan Reviewer")
    expect { described_class.call(admin_user: admin) }.not_to change(PaperTrail::Version, :count)
  end
end
