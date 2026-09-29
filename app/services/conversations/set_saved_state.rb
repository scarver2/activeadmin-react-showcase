# app/services/conversations/set_saved_state.rb
# frozen_string_literal: true

module Conversations
  class SetSavedState
    class NotAuthorized < StandardError; end

    MAX_BUSY_RETRIES = 4

    def self.call(message:, membership:, saved:)
      raise ArgumentError, "saved must be boolean" unless [ true, false ].include?(saved)

      attempts = 0
      begin
        apply(message:, membership:, saved:)
      rescue ActiveRecord::RecordNotUnique
        raise unless saved

        SavedMessage.find_by!(membership_id: membership.id, message_id: message.id)
      rescue ActiveRecord::StatementInvalid => error
        raise unless sqlite_busy?(error) && attempts < MAX_BUSY_RETRIES

        attempts += 1
        sleep(0.01 * attempts)
        retry
      end
    end

    def self.apply(message:, membership:, saved:)
      authorized_membership = authorized_membership_for(message:, membership:)

      authorized_membership.with_lock do
        raise NotAuthorized unless message_still_belongs_to?(message:, membership: authorized_membership)

        if saved
          timestamp = Time.current
          SavedMessage.insert_all(
            [ {
              chat_room_id: authorized_membership.conversation_id,
              created_at: timestamp,
              membership_id: authorized_membership.id,
              message_id: message.id,
              updated_at: timestamp
            } ],
            unique_by: "index_saved_messages_on_membership_and_message"
          )
          return SavedMessage.find_by!(membership: authorized_membership, message:)
        end

        SavedMessage.where(membership: authorized_membership, message:).delete_all
        nil
      end
    end
    private_class_method :apply

    def self.authorized_membership_for(message:, membership:)
      ConversationMembership.find_by(
        id: membership.id,
        chat_room_id: message.conversation_id
      ) || raise(NotAuthorized)
    end
    private_class_method :authorized_membership_for

    def self.message_still_belongs_to?(message:, membership:)
      Message.exists?(id: message.id, chat_room_id: membership.conversation_id)
    end
    private_class_method :message_still_belongs_to?

    def self.sqlite_busy?(error)
      error.cause.is_a?(SQLite3::BusyException)
    end
    private_class_method :sqlite_busy?
  end
end
