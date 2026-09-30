# app/services/activity_center/perform_action.rb
# frozen_string_literal: true

module ActivityCenter
  class PerformAction
    def self.call(notification:)
      new(notification:).call
    end

    def initialize(notification:)
      @notification = notification
    end

    def call
      item = notification.event.record
      unless item.is_a?(WorkflowItem) && item.state == "review"
        raise ActivityCenter::UnsupportedAction, "This notification no longer has an available action."
      end

      Workflow::Move.call(item:, state: "done", position: WorkflowItem.where(state: "done").count)
      ActivityCenter::SetReadState.call(notification:, read: true)
      item
    end

    private

    attr_reader :notification
  end
end
