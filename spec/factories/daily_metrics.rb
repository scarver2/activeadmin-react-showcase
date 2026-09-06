# spec/factories/daily_metrics.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :daily_metric do
    account
    recorded_on { Date.current }
    active_users { 25 }
    error_count { 1 }
    p95_ms { 180 }
    request_count { 900 }
    revenue_cents { 125_000 }
  end
end
