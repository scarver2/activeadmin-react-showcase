# app/models/reversible_change.rb
# frozen_string_literal: true

class ReversibleChange < ApplicationRecord
  belongs_to :admin_user
  belongs_to :account
  has_many :events, class_name: "ReversibleChangeEvent", dependent: :restrict_with_exception

  validates :request_key, presence: true, length: { maximum: 80 }, uniqueness: { scope: :admin_user_id }
  validates :before_value, :after_value, inclusion: { in: Account::REGIONS }
  validates :expires_at, :applied_lock_version, presence: true

  def undo_state(now: Time.current)
    return "already undone" if undone_at
    return "expired" if now >= expires_at
    return "authorization changed" unless InlineEditing::Policy.new(admin_user:, account:).permitted?("region")
    return "account changed" unless account.lock_version == applied_lock_version && account.region == after_value

    "available"
  end
end
