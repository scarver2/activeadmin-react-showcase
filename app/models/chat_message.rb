# app/models/chat_message.rb
# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  belongs_to :author, class_name: "ChatParticipant", inverse_of: :messages
  belongs_to :chat_room

  validates :body, length: { in: 1..500 }
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :chat_room_id }
  validate :author_belongs_to_room

  private

  def author_belongs_to_room
    return if author.nil? || chat_room.nil? || author.chat_room_id == chat_room_id

    errors.add(:author, "must participate in the message room")
  end
end
