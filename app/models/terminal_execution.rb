# app/models/terminal_execution.rb
# frozen_string_literal: true

class TerminalExecution < ApplicationRecord
  STATES = %w[queued running completed failed cancelled].freeze
  TERMINAL_STATES = %w[completed failed cancelled].freeze

  belongs_to :admin_user
  has_many :outputs, -> { order(:sequence) }, class_name: "TerminalOutput", dependent: :destroy, inverse_of: :terminal_execution

  before_validation :assign_public_id, on: :create

  validates :command_key, inclusion: { in: ->(_) { SafeTerminal::Commands.keys } }
  validates :display_command, :idempotency_key, :public_id, presence: true
  validates :idempotency_key, length: { maximum: 100 }
  validates :idempotency_key, uniqueness: { scope: :admin_user_id }
  validates :public_id, uniqueness: true
  validates :state, inclusion: { in: STATES }

  scope :recent_first, -> { order(created_at: :desc) }

  def broadcast_key
    "terminal-executions:admin-user:#{admin_user_id}:#{public_id}"
  end

  def terminal?
    state.in?(TERMINAL_STATES)
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
