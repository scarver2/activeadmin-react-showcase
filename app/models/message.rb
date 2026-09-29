# app/models/message.rb
# frozen_string_literal: true

class Message < ApplicationRecord
  alias_attribute :author_id, :conversation_membership_id
  alias_attribute :chat_room_id, :conversation_id

  belongs_to :conversation, inverse_of: :messages
  belongs_to :conversation_membership, inverse_of: :messages
  before_validation :assign_public_id, on: :create
  after_create_commit :advance_conversation_activity

  validates :body, length: { in: 1..500 }
  validates :public_id, presence: true, uniqueness: true
  validates :sequence,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :conversation_id }
  validate :membership_belongs_to_conversation

  scope :chronological, -> { order(sequence: :asc, id: :asc) }

  # Compatibility for the accepted Operator Chat precursor during migration.
  def author
    conversation_membership
  end

  def author=(value)
    self.conversation_membership = value
  end

  def chat_room
    conversation
  end

  def chat_room=(value)
    self.conversation = value
  end

  private

  def advance_conversation_activity
    conversation.with_lock do
      next if conversation.last_activity_at >= created_at

      conversation.update!(last_activity_at: created_at)
    end
  end

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end

  def membership_belongs_to_conversation
    return if conversation_membership.nil? || conversation.nil? || conversation_membership.conversation_id == conversation_id

    errors.add(:conversation_membership, "must participate in the message conversation")
    errors.add(:author, "must participate in the message room")
  end
end
