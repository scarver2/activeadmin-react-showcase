# app/models/message.rb
# frozen_string_literal: true

class Message < ApplicationRecord
  EDIT_WINDOW = 15.minutes
  WITHDRAWN_BODY = "[withdrawn]".freeze

  self.table_name = "chat_messages"

  alias_attribute :conversation_id, :chat_room_id
  alias_attribute :conversation_membership_id, :author_id

  belongs_to :conversation, foreign_key: :chat_room_id, inverse_of: :messages
  belongs_to :author,
             class_name: "ConversationMembership",
             foreign_key: :author_id,
             inverse_of: :messages
  belongs_to :reply_to_message, class_name: "Message", optional: true, inverse_of: :replies
  has_many :dispositions,
           class_name: "MessageDisposition",
           dependent: :restrict_with_error,
           inverse_of: :message
  has_many :mentions,
           class_name: "MessageMention",
           dependent: :restrict_with_error,
           inverse_of: :message
  has_many :replies,
           class_name: "Message",
           dependent: :restrict_with_error,
           foreign_key: :reply_to_message_id,
           inverse_of: :reply_to_message
  has_many :saved_messages,
           dependent: :delete_all,
           inverse_of: :message
  before_validation :assign_public_id, on: :create
  after_create :advance_conversation_activity

  validates :body, length: { in: 1..500 }
  validates :public_id, presence: true, uniqueness: true
  validates :sequence,
            numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: :conversation_id }
  validate :membership_belongs_to_conversation
  validate :reply_belongs_to_conversation

  scope :chronological, -> { order(sequence: :asc, id: :asc) }

  def editable_by?(membership, at: Time.current)
    author == membership && withdrawn_at.nil? && created_at >= EDIT_WINDOW.ago(at)
  end

  def withdrawn?
    withdrawn_at.present?
  end

  # Compatibility for the accepted Operator Chat precursor during migration.
  def conversation_membership
    author
  end

  def conversation_membership=(value)
    self.author = value
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

  def reply_belongs_to_conversation
    return if reply_to_message.nil? || conversation.nil? || reply_to_message.conversation_id == conversation_id

    errors.add(:reply_to_message, "must belong to the message conversation")
  end
end
