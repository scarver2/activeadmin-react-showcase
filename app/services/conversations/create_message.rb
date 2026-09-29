# app/services/conversations/create_message.rb
# frozen_string_literal: true

module Conversations
  class CreateMessage
    ATTEMPTS = 5
    BASE_DELAY = 0.01
    class NotAuthorized < StandardError; end

    def self.call(conversation:, membership:, body:, public_id: nil, reply_to: nil, mentioned_memberships: [])
      mentions = normalized_mentions(mentioned_memberships)
      authorize!(conversation:, membership:, reply_to:, mentioned_memberships: mentions)
      attempts = 0
      begin
        conversation.with_lock do
          conversation.reload
          membership.with_lock do
            message = conversation.messages.build(
              body: body.to_s.strip,
              conversation_membership: membership,
              public_id:,
              reply_to_message: reply_to,
              sequence: conversation.messages.maximum(:sequence).to_i + 1
            )
            mentions.each do |mentioned_membership|
              message.mentions.build(
                conversation:,
                mentioned_membership:,
                mention_text: "@#{mentioned_membership.display_name}"
              )
            end
            message.save!
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

    def self.normalized_mentions(memberships)
      Array(memberships).uniq(&:id)
    end
    private_class_method :normalized_mentions

    def self.authorize!(conversation:, membership:, reply_to:, mentioned_memberships:)
      authorized = membership.conversation_id == conversation.id &&
                   (reply_to.nil? || reply_to.conversation_id == conversation.id) &&
                   mentioned_memberships.all? { |mentioned| mentioned.conversation_id == conversation.id }
      raise NotAuthorized unless authorized
    end
    private_class_method :authorize!
  end
end
