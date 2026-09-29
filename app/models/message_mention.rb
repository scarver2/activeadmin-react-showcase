# app/models/message_mention.rb
# frozen_string_literal: true

class MessageMention < ApplicationRecord
  belongs_to :conversation, class_name: "Conversation", foreign_key: :chat_room_id
  belongs_to :mentioned_membership,
             class_name: "ConversationMembership",
             inverse_of: :received_mentions
  belongs_to :message, inverse_of: :mentions

  validates :mention_text, length: { in: 2..81 }
  validates :mentioned_membership_id, uniqueness: { scope: :message_id }
  validate :records_belong_to_conversation

  private

  def records_belong_to_conversation
    return if conversation.nil?

    errors.add(:message, "must belong to the mention conversation") if message&.conversation_id != conversation.id
    return if mentioned_membership&.conversation_id == conversation.id

    errors.add(:mentioned_membership, "must belong to the mention conversation")
  end
end
