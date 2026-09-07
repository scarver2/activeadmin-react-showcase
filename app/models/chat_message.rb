# app/models/chat_message.rb
# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  PARTICIPANTS = {
    "maya" => "Maya Ortiz",
    "jordan" => "Jordan Lee",
    "operator" => "You"
  }.freeze

  belongs_to :chat_room

  validates :author_key, inclusion: { in: PARTICIPANTS.keys }
  validates :author_name, inclusion: { in: PARTICIPANTS.values }
  validates :body, length: { in: 1..500 }
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :chat_room_id }
end
