# spec/services/audit_history/profile_history_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHistory::ProfileHistory do
  it "serializes provenance and uses paper_trail_diff for restoration preview" do
    profile = nil
    PaperTrail.request(whodunnit: "Avery") do
      profile = create(:audit_profile)
      profile.update!(name: "Changed", preferences: { nested: [ 1, 2 ] }.to_json)
    end
    history = described_class.new(profile)
    expect(history.as_json.last).to include(actor: "Avery", event: "update")
    expect(history.preview(profile.versions.last.id)).to include(:attributes)
  end
end
