# app/services/conversations/create_message.rb
# frozen_string_literal: true

module Conversations
  class CreateMessage
    ATTEMPTS = 5
    BASE_DELAY = 0.01
    class NotAuthorized < StandardError; end
    class ReplayConflict < StandardError; end

    def self.call(conversation:, membership:, body:, public_id: nil, reply_to: nil, mentioned_memberships: [], attachment: nil)
      normalized_body = body.to_s.strip
      mentions = normalized_mentions(mentioned_memberships)
      authorize!(conversation:, membership:, reply_to:, mentioned_memberships: mentions)
      attempts = 0
      uploaded_attachment = nil
      begin
        conversation.with_lock do
          conversation.reload
          membership.with_lock do
            replay = replayed_message(
              attachment:,
              body: normalized_body,
              conversation:,
              membership:,
              mentioned_memberships: mentions,
              public_id:,
              reply_to:
            )
            return replay if replay

            message = conversation.messages.build(
              body: normalized_body,
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
            uploaded_attachment = Conversations::AttachUpload.call(message:, upload: attachment) if attachment.present?
            membership.update!(last_read_message: message, last_read_at: Time.current)
            RealtimeChange.record!(conversation:, kind: "message_created")
            message
          end
        end
      rescue ActiveRecord::StatementInvalid => error
        Conversations::AttachUpload.cleanup(uploaded_attachment)
        uploaded_attachment = nil
        attempts += 1
        raise unless sqlite_busy?(error) && attempts < ATTEMPTS

        sleep(BASE_DELAY * attempts)
        retry
      rescue StandardError
        Conversations::AttachUpload.cleanup(uploaded_attachment)
        raise
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

    def self.replayed_message(attachment:, body:, conversation:, membership:, mentioned_memberships:, public_id:, reply_to:)
      return if public_id.blank?

      existing = Message.includes(:mentions).find_by(public_id:)
      return if existing.nil?

      matching = attachment.blank? &&
                 existing.conversation_id == conversation.id &&
                 existing.author_id == membership.id &&
                 existing.body == body &&
                 existing.reply_to_message_id == reply_to&.id &&
                 existing.mentions.map(&:mentioned_membership_id).sort == mentioned_memberships.map(&:id).sort
      raise ReplayConflict unless matching

      existing
    end
    private_class_method :replayed_message

    def self.authorize!(conversation:, membership:, reply_to:, mentioned_memberships:)
      authorized = membership.conversation_id == conversation.id &&
                   (reply_to.nil? || reply_to.conversation_id == conversation.id) &&
                   mentioned_memberships.all? { |mentioned| mentioned.conversation_id == conversation.id }
      raise NotAuthorized unless authorized
    end
    private_class_method :authorize!
  end
end
