# app/models/handoff_event.rb
# frozen_string_literal: true

class HandoffEvent < ApplicationRecord
  COMMAND_ID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  belongs_to :handoff_item, inverse_of: :events

  validates :command_id, format: { with: COMMAND_ID_PATTERN }, uniqueness: { scope: :handoff_item_id }
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :handoff_item_id }
  validates :action, inclusion: { in: %w[assign advance approve hand_back cancel] }
  validates :actor, inclusion: { in: %w[human deterministic_agent] }
  validates :evidence, length: { in: 1..500 }
end
