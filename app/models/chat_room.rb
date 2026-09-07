# app/models/chat_room.rb
# frozen_string_literal: true

class ChatRoom < ApplicationRecord
  has_many :messages, class_name: "ChatMessage", dependent: :destroy

  validates :name, :public_id, presence: true
  validates :public_id, uniqueness: true

  def broadcast_key
    "operator_chat:#{public_id}"
  end
end
