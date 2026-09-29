# app/models/scheduled_message.rb
# frozen_string_literal: true

class ScheduledMessage < ApplicationRecord
  STATES = %w[pending delivered cancelled failed].freeze

  alias_attribute :conversation_id, :chat_room_id

  belongs_to :admin_user
  belongs_to :conversation, foreign_key: :chat_room_id, inverse_of: :scheduled_messages
  belongs_to :delivered_message, class_name: "Message", optional: true

  before_validation :assign_public_ids, on: :create

  validates :body, length: { in: 1..500 }
  validates :delivery_public_id, presence: true, uniqueness: true
  validates :public_id, presence: true, uniqueness: true
  validates :scheduled_for, presence: true
  validates :state, inclusion: { in: STATES }
  validates :cancelled_at, presence: true, if: -> { state == "cancelled" }
  validates :delivered_at, :delivered_message, presence: true, if: -> { state == "delivered" }
  validates :failed_at, :failure_code, presence: true, if: -> { state == "failed" }
  validate :delivered_message_belongs_to_conversation

  scope :chronological, -> { order(scheduled_for: :asc, id: :asc) }
  scope :pending, -> { where(state: "pending") }

  def manageable?
    state.in?(%w[pending failed])
  end

  def failed?
    state == "failed"
  end

  def pending?
    state == "pending"
  end

  private

  def assign_public_ids
    self.delivery_public_id ||= SecureRandom.uuid
    self.public_id ||= SecureRandom.uuid
  end

  def delivered_message_belongs_to_conversation
    return if delivered_message.nil? || delivered_message.conversation_id == conversation_id

    errors.add(:delivered_message, "must belong to the scheduled conversation")
  end
end
