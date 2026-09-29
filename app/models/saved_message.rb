# app/models/saved_message.rb
# frozen_string_literal: true

class SavedMessage < ApplicationRecord
  belongs_to :conversation, foreign_key: :chat_room_id, inverse_of: :saved_messages
  belongs_to :membership,
             class_name: "ConversationMembership",
             inverse_of: :saved_messages
  belongs_to :message, inverse_of: :saved_messages

  validates :message_id, uniqueness: { scope: :membership_id }
  validate :membership_and_message_share_conversation

  private

  def membership_and_message_share_conversation
    return if conversation.nil? || membership.nil? || message.nil?
    return if membership.conversation_id == conversation.id && message.conversation_id == conversation.id

    errors.add(:base, "membership and message must belong to the saved conversation")
  end
end
