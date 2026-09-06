# app/models/operation.rb
# frozen_string_literal: true

class Operation < ApplicationRecord
  KINDS = %w[successful_demo failing_demo].freeze
  STATES = %w[queued running completed failed cancelled].freeze
  TERMINAL_STATES = %w[completed failed cancelled].freeze

  belongs_to :admin_user
  belongs_to :retry_of, class_name: "Operation", optional: true
  has_many :events, -> { order(:sequence) }, class_name: "OperationEvent", dependent: :destroy, inverse_of: :operation
  has_many :retries, class_name: "Operation", foreign_key: :retry_of_id, dependent: :nullify, inverse_of: :retry_of

  before_validation :assign_public_id, on: :create

  validates :kind, inclusion: { in: KINDS }
  validates :message, :public_id, presence: true
  validates :progress, inclusion: { in: 0..100 }
  validates :public_id, uniqueness: true
  validates :state, inclusion: { in: STATES }

  scope :recent_first, -> { order(created_at: :desc) }

  def broadcast_key
    "operations:admin-user:#{admin_user_id}:#{public_id}"
  end

  def cancelable?
    !terminal?
  end

  def retryable?
    terminal?
  end

  def terminal?
    state.in?(TERMINAL_STATES)
  end

  def latest_envelope
    events.last&.envelope || {
      operation_id: public_id,
      idempotency_key: "#{public_id}:0",
      sequence: 0,
      state:,
      progress:,
      message:,
      result:,
      result_metadata: nil,
      error:,
      occurred_at: updated_at.iso8601(6)
    }
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
