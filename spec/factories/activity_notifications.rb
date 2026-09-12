# spec/factories/activity_notifications.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :activity_notification do
    association :admin_user
    sequence(:body) { |number| "Synthetic activity #{number}" }
    deep_link { "/admin/accounts" }
    kind { "account" }
    occurred_at { Time.zone.parse("2026-09-07 09:00:00") }
    sequence(:sequence)
    sequence(:subject) { |number| "Notification #{number}" }
  end
end
