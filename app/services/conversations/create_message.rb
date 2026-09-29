# app/services/conversations/create_message.rb
# frozen_string_literal: true

module Conversations
  class CreateMessage
    ATTEMPTS = 5
    BASE_DELAY = 0.01

    def self.call(conversation:, membership:, body:, public_id: nil)
      attempts = 0
      begin
        conversation.with_lock do
          conversation.reload
          membership.with_lock do
            message = conversation.messages.create!(
              body: body.to_s.strip,
              conversation_membership: membership,
              public_id:,
              sequence: conversation.messages.maximum(:sequence).to_i + 1
            )
            membership.update!(last_read_message: message, last_read_at: Time.current)
            message
          end
        end
      rescue ActiveRecord::StatementInvalid => error
        attempts += 1
        raise unless sqlite_busy?(error) && attempts < ATTEMPTS

        sleep(BASE_DELAY * attempts)
        retry
      end
    end

    def self.sqlite_busy?(error)
      error.cause.class.name.in?(%w[SQLite3::BusyException SQLite3::LockedException])
    end
    private_class_method :sqlite_busy?
  end
end
