# app/models/telemetry_request_sample.rb
# frozen_string_literal: true

class TelemetryRequestSample < ApplicationRecord
  validates :duration_ms, numericality: { greater_than_or_equal_to: 0 }
  validates :occurred_at, presence: true
  validates :status, inclusion: { in: 100..599 }
end
