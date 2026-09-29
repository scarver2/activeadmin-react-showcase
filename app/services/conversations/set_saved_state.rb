# app/services/conversations/set_saved_state.rb
# frozen_string_literal: true

module Conversations
  class SetSavedState
    class NotAuthorized < StandardError; end

    def self.call(message:, membership:, saved:)
      raise ArgumentError, "saved must be boolean" unless [ true, false ].include?(saved)

      authorized_membership = authorized_membership_for(message:, membership:)

      authorized_membership.with_lock do
        raise NotAuthorized unless message_still_belongs_to?(message:, membership: authorized_membership)

        if saved
          SavedMessage.find_or_create_by!(
            conversation: authorized_membership.conversation,
            membership: authorized_membership,
            message:
          )
        else
          SavedMessage.where(membership: authorized_membership, message:).delete_all
          nil
        end
      end
    end

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
  end
end
