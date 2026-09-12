# app/models/agent_event.rb
# frozen_string_literal: true

class AgentEvent < ApplicationRecord
  KINDS = %w[status response citation result].freeze

  belongs_to :agent_run, inverse_of: :events

  validates :content, :occurred_at, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :progress, inclusion: { in: 0..100 }
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :agent_run_id }

  def envelope
    { run_id: agent_run.public_id, sequence:, kind:, content:, progress:, metadata:, occurred_at: occurred_at.iso8601(6) }
  end
end
