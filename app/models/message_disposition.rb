# app/models/message_disposition.rb
# frozen_string_literal: true

class MessageDisposition < ApplicationRecord
  KINDS = %w[like dislike question].freeze

  belongs_to :conversation, class_name: "Conversation", foreign_key: :chat_room_id
  belongs_to :membership, class_name: "ConversationMembership", inverse_of: :message_dispositions
  belongs_to :message, inverse_of: :dispositions

  validates :kind, inclusion: { in: KINDS }
  validates :membership_id, uniqueness: { scope: :message_id }
  validate :records_belong_to_conversation

  private

  def records_belong_to_conversation
    return if conversation.nil?

    errors.add(:message, "must belong to the disposition conversation") if message&.conversation_id != conversation.id
    return if membership&.conversation_id == conversation.id

    errors.add(:membership, "must belong to the disposition conversation")
  end
end
