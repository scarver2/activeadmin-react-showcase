# app/models/message_attachment.rb
# frozen_string_literal: true

class MessageAttachment < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png text/plain].freeze
  MAXIMUM_BYTES = 1.megabyte

  belongs_to :conversation, class_name: "Conversation", foreign_key: :chat_room_id
  belongs_to :message, inverse_of: :attachment
  has_one_attached :file

  before_validation :assign_public_id, on: :create

  validates :message_id, uniqueness: true
  validates :public_id, presence: true, uniqueness: true
  validate :acceptable_file
  validate :message_belongs_to_conversation

  def inline?
    file.blob.content_type.in?(%w[image/jpeg image/png])
  end

  private

  def acceptable_file
    return errors.add(:file, "must be attached") unless file.attached?

    errors.add(:file, "type is not allowed") unless file.blob.content_type.in?(ALLOWED_CONTENT_TYPES)
    errors.add(:file, "must be 1 MB or smaller") if file.blob.byte_size > MAXIMUM_BYTES
  end

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end

  def message_belongs_to_conversation
    return if message.nil? || conversation.nil? || message.conversation_id == conversation.id

    errors.add(:message, "must belong to the attachment conversation")
  end
end
