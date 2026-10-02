# app/models/handoff_item.rb
# frozen_string_literal: true

# An isolated, synthetic work item. Agent progress can never authorize completion.
class HandoffItem < ApplicationRecord
  STATES = %w[human agent approval completed cancelled].freeze

  belongs_to :admin_user
  has_many :events, -> { order(:sequence) }, class_name: "HandoffEvent", dependent: :destroy, inverse_of: :handoff_item

  before_validation :assign_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true
  validates :title, length: { in: 1..120 }
  validates :state, inclusion: { in: STATES }
  validates :progress, inclusion: { in: 0..100 }

  def broadcast_key = "handoffs:#{admin_user_id}:#{public_id}"

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
