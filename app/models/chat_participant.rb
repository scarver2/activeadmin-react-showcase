# app/models/chat_participant.rb
# frozen_string_literal: true

class ChatParticipant < ApplicationRecord
  belongs_to :chat_room
  has_many :messages,
           class_name: "ChatMessage",
           foreign_key: :author_id,
           inverse_of: :author,
           dependent: :restrict_with_error

  validates :display_name, length: { in: 1..80 }
  validates :key, format: { with: /\A[a-z][a-z0-9_-]*\z/ }, uniqueness: { scope: :chat_room_id }
end
