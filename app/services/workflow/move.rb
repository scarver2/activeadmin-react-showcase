# app/services/workflow/move.rb
# frozen_string_literal: true

module Workflow
  class Move
    def self.call(item:, state:, position:)
      new(item:, state:, position:).call
    end

    def initialize(item:, state:, position:)
      @item = item
      @state = state.to_s
      @position = Integer(position.to_s, 10, exception: false)
    end

    def call
      validate_request!

      WorkflowItem.transaction do
        relevant_items = WorkflowItem.where(state: [ item.state, state ]).ordered.lock.to_a
        moving_item = relevant_items.find { |candidate| candidate.id == item.id }
        target_items = relevant_items.reject { |candidate| candidate.id == item.id || candidate.state != state }
        validate_position!(target_items.length)

        target_items.insert(position, moving_item)
        persist_positions(relevant_items.reject { |candidate| candidate.id == item.id || candidate.state != item.state }, item.state) if item.state != state
        persist_positions(target_items, state)
        moving_item
      end
    end

    private

    attr_reader :item, :position, :state

    def invalid!(attribute, message)
      item.errors.add(attribute, message)
      raise ActiveRecord::RecordInvalid, item
    end

    def persist_positions(items, target_state)
      items.each_with_index do |candidate, index|
        candidate.update!(state: target_state, position: index)
      end
    end

    def validate_position!(maximum)
      invalid!(:position, "must be between 0 and #{maximum}") unless position&.between?(0, maximum)
    end

    def validate_request!
      invalid!(:state, "is not a supported workflow state") unless WorkflowItem::STATES.include?(state)
      invalid!(:position, "must be an integer") unless position
    end
  end
end
