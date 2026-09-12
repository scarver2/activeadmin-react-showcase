# app/models/agent_run.rb
# frozen_string_literal: true

class AgentRun < ApplicationRecord
  STATES = %w[queued running completed cancelled].freeze
  TERMINAL_STATES = %w[completed cancelled].freeze

  belongs_to :admin_user
  has_many :events, -> { order(:sequence) }, class_name: "AgentEvent", dependent: :destroy, inverse_of: :agent_run

  before_validation :assign_public_id, on: :create

  validates :progress, inclusion: { in: 0..100 }
  validates :prompt, length: { in: 1..500 }
  validates :public_id, presence: true, uniqueness: true
  validates :state, inclusion: { in: STATES }

  scope :recent_first, -> { order(created_at: :desc) }

  def broadcast_key = "agent-runs:admin-user:#{admin_user_id}:#{public_id}"
  def terminal? = state.in?(TERMINAL_STATES)

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
