# app/models/conversation_membership.rb
# frozen_string_literal: true

class ConversationMembership < ApplicationRecord
  self.table_name = "chat_participants"

  alias_attribute :conversation_id, :chat_room_id

  after_initialize :default_to_authenticated_identity, if: :new_record?

  belongs_to :admin_user, optional: true
  belongs_to :conversation, foreign_key: :chat_room_id, inverse_of: :memberships
  belongs_to :last_read_message, class_name: "Message", optional: true
  has_many :messages,
           class_name: "Message",
           foreign_key: :author_id,
           inverse_of: :author,
           dependent: :restrict_with_error
  has_many :message_dispositions,
           dependent: :restrict_with_error,
           foreign_key: :membership_id,
           inverse_of: :membership
  has_many :received_mentions,
           class_name: "MessageMention",
           dependent: :restrict_with_error,
           foreign_key: :mentioned_membership_id,
           inverse_of: :mentioned_membership
  has_many :saved_messages,
           dependent: :delete_all,
           foreign_key: :membership_id,
           inverse_of: :membership

  validates :admin_user_id, uniqueness: { scope: :conversation_id }, allow_nil: true
  validates :admin_user, absence: true, if: :legacy_identity?
  validates :admin_user, presence: true, unless: :legacy_identity?
  validates :display_name, length: { in: 1..80 }
  validates :key, format: { with: /\A[a-z][a-z0-9_-]*\z/ }, uniqueness: { scope: :conversation_id }
  validate :last_read_message_belongs_to_conversation

  def mark_read_through!(message)
    raise ArgumentError, "message must belong to the membership conversation" unless message.conversation_id == conversation_id

    with_lock do
      reload
      return self if last_read_message.present? && last_read_message.sequence >= message.sequence

      update!(last_read_message: message, last_read_at: Time.current)
    end
    self
  end

  def mark_unread!
    update!(last_read_message: nil, last_read_at: nil)
    self
  end

  def mark_unread_from!(message)
    raise ArgumentError, "message must belong to the membership conversation" unless message.conversation_id == conversation_id

    with_lock do
      reload
      return self if last_read_message.nil?

      previous_message = conversation.messages.where(Message.arel_table[:sequence].lt(message.sequence)).order(sequence: :desc).first
      return self if previous_message.present? && previous_message.sequence >= last_read_message.sequence

      update!(last_read_message: previous_message, last_read_at: previous_message.present? ? Time.current : nil)
    end
    self
  end

  def unread_count
    conversation.messages.where(Message.arel_table[:sequence].gt(last_read_message&.sequence || 0)).count
  end

  # Compatibility for the accepted Operator Chat precursor during migration.
  def authored_messages
    messages
  end

  def chat_room
    conversation
  end

  def chat_room=(value)
    self.conversation = value
  end

  private

  def default_to_authenticated_identity
    self.legacy_identity = false unless will_save_change_to_legacy_identity?
  end

  def last_read_message_belongs_to_conversation
    return if last_read_message.nil? || last_read_message.conversation_id == conversation_id

    errors.add(:last_read_message, "must belong to the membership conversation")
  end
end
