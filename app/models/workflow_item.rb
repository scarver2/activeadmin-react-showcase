# app/models/workflow_item.rb
# frozen_string_literal: true

class WorkflowItem < ApplicationRecord
  STATES = %w[backlog ready in_progress review done].freeze

  scope :ordered, -> { order(:state, :position, :id) }

  validates :context, length: { maximum: 500 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :state, inclusion: { in: STATES }
  validates :title, length: { in: 1..120 }
end
