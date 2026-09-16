# app/services/activity_center/seed.rb
# frozen_string_literal: true

module ActivityCenter
  class Seed
    BLUEPRINTS = [
      [ "account", "Account review requested", "Bluebonnet Logistics needs an owner review.", "/admin/accounts" ],
      [ "operation", "Import completed", "The synthetic Northwind import completed safely.", "/admin/live_jobs" ],
      [ "schedule", "Schedule changed", "The launch review moved to the afternoon.", "/admin/calendar_scheduler" ],
      [ "account", "Trial follow-up", "High Plains Supply is ready for follow-up.", "/admin/relationship_explorer" ]
    ].freeze

    def self.call(admin_user:)
      return admin_user.activity_notifications.newest_first.limit(100) if admin_user.activity_notifications.exists?

      base_time = Time.zone.parse("2026-09-07 09:00:00")
      BLUEPRINTS.each_with_index do |(kind, subject, body, deep_link), index|
        admin_user.activity_notifications.create!(
          body:, deep_link:, kind:, occurred_at: base_time + index.hours,
          read_at: index == 3 ? nil : base_time + (index + 1).hours,
          sequence: index + 1, subject:
        )
      end
      admin_user.activity_notifications.newest_first.limit(100)
    end
  end
end
