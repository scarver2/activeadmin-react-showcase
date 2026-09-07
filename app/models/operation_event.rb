# app/models/operation_event.rb
# frozen_string_literal: true

class OperationEvent < ApplicationRecord
  belongs_to :operation, inverse_of: :events

  validates :idempotency_key, :message, :occurred_at, presence: true
  validates :idempotency_key, uniqueness: true
  validates :progress, inclusion: { in: 0..100 }
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :operation_id }
  validates :state, inclusion: { in: Operation::STATES }

  def envelope
    {
      operation_id: operation.public_id,
      idempotency_key:,
      sequence:,
      state:,
      progress:,
      message:,
      result:,
      result_metadata: nil,
      error:,
      occurred_at: occurred_at.iso8601(6)
    }
  end
end
