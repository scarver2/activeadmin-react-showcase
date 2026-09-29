# app/models/conversation.rb
# frozen_string_literal: true

class Conversation < ApplicationRecord
  before_validation :assign_defaults, on: :create

  has_many :memberships,
           class_name: "ConversationMembership",
           dependent: :restrict_with_error,
           inverse_of: :conversation
  has_many :messages, dependent: :restrict_with_error, inverse_of: :conversation

  validates :last_activity_at, presence: true
  validates :public_id, presence: true, uniqueness: true
  validates :title, length: { in: 1..120 }
  validates :topic, length: { in: 1..160 }, allow_nil: true

  scope :by_recent_activity, -> { order(last_activity_at: :desc, id: :desc) }

  def member?(admin_user)
    admin_user.present? && memberships.exists?(admin_user:)
  end

  def membership_for(admin_user)
    memberships.find_by(admin_user:)
  end

  def broadcast_key
    "operator_chat:#{public_id}"
  end

  def name
    title
  end

  def name=(value)
    self.title = value
  end

  # Compatibility for the accepted Operator Chat precursor during migration.
  def participants
    memberships
  end

  private

  def assign_defaults
    self.last_activity_at ||= Time.current
    self.public_id ||= SecureRandom.uuid
  end
end
