# app/models/activity_notification.rb
# frozen_string_literal: true

class ActivityNotification < ApplicationRecord
  KINDS = %w[account operation schedule].freeze

  belongs_to :admin_user

  validates :body, :deep_link, :occurred_at, :sequence, :subject, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :sequence, uniqueness: { scope: :admin_user_id }
  validate :deep_link_is_local

  scope :newest_first, -> { order(occurred_at: :desc, sequence: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def mark_read!
    update!(read_at: Time.current) unless read_at?
  end

  def mark_unread!
    update!(read_at: nil) if read_at?
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "admin_user" ]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id body deep_link id kind occurred_at read_at sequence subject]
  end

  private

  def deep_link_is_local
    errors.add(:deep_link, "must be an admin path") unless deep_link.to_s.start_with?("/admin/")
  end
end
