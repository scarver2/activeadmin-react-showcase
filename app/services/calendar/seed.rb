# app/services/calendar/seed.rb
# frozen_string_literal: true

module Calendar
  class Seed
    BLUEPRINTS = [
      [ "Central launch review", 1, 15, 90, "America/Chicago", "Austin room", "Review the deterministic launch checklist." ],
      [ "London partner briefing", 2, 14, 60, "Europe/London", "Video room", "Compare one instant across display zones." ],
      [ "Tokyo release handoff", 3, 1, 60, "Asia/Tokyo", "Operations bridge", "Hand off a bounded synthetic release." ],
      [ "Platform maintenance", 4, 18, 120, "UTC", "Primary host", "Adjacent moves are accepted; overlaps are rejected." ]
    ].freeze

    def self.call(admin_user:)
      week = Date.current.beginning_of_week

      BLUEPRINTS.map do |title, day_offset, hour, duration_minutes, time_zone, location, notes|
        starts_at = Time.use_zone("UTC") { Time.zone.local(week.year, week.month, week.day, hour) + day_offset.days }
        event = admin_user.schedule_events.find_or_initialize_by(title:)
        event.update!(ends_at: starts_at + duration_minutes.minutes, location:, notes:, starts_at:, time_zone:)
        event
      end
    end
  end
end
