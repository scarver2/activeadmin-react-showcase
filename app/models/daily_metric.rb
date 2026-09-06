# app/models/daily_metric.rb
# frozen_string_literal: true

class DailyMetric < ApplicationRecord
  belongs_to :account

  validates :active_users, :error_count, :p95_ms, :request_count, :revenue_cents,
            numericality: { greater_than_or_equal_to: 0 }
  validates :recorded_on, presence: true, uniqueness: { scope: :account_id }
end
