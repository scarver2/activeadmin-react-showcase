# app/services/audit_history/seed.rb
# frozen_string_literal: true

module AuditHistory
  class Seed
    def self.call(admin_user:)
      profile = admin_user.audit_profiles.first_or_initialize(name: "Bluebonnet Operations")
      return profile if profile.persisted? && profile.versions.count >= 3

      PaperTrail.request(whodunnit: "Avery Admin") do
        profile.update!(plan: "Starter", preferences: { alerts: [ "email" ], region: "Central" }.to_json)
        profile.update!(plan: "Growth", preferences: { alerts: %w[email sms], region: "Central" }.to_json)
      end
      PaperTrail.request(whodunnit: "Morgan Reviewer") do
        profile.update!(name: "Bluebonnet Operations Group", preferences: { alerts: [ "sms" ], region: "West" }.to_json)
      end
      profile
    end
  end
end
