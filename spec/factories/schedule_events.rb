# spec/factories/schedule_events.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :schedule_event do
    association :admin_user
    sequence(:title) { |number| "Scheduled event #{number}" }
    starts_at { Time.zone.parse("2026-09-14 14:00:00 UTC") }
    ends_at { starts_at + 1.hour }
    time_zone { "America/Chicago" }
    location { "Austin room" }
    notes { "Synthetic schedule context." }
  end
end
