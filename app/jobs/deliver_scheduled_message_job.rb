# app/jobs/deliver_scheduled_message_job.rb
# frozen_string_literal: true

class DeliverScheduledMessageJob < ApplicationJob
  queue_as :default

  def perform(scheduled_message_id, expected_revision)
    scheduled_message = ScheduledMessage.find_by(id: scheduled_message_id)
    return unless scheduled_message

    Conversations::DeliverScheduledMessage.call(scheduled_message:, expected_revision:)
  end
end
