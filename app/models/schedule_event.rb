# app/models/schedule_event.rb
# frozen_string_literal: true

class ScheduleEvent < ApplicationRecord
  MAXIMUM_DURATION = 12.hours
  TIME_ZONES = [ "America/Chicago", "America/New_York", "Asia/Tokyo", "Europe/London", "UTC" ].freeze

  belongs_to :admin_user

  scope :chronological, -> { order(:starts_at, :ends_at, :id) }
  scope :overlapping, lambda { |starts_at, ends_at|
    where(arel_table[:starts_at].lt(ends_at).and(arel_table[:ends_at].gt(starts_at)))
  }

  validates :ends_at, :starts_at, :time_zone, :title, presence: true
  validates :location, length: { maximum: 120 }
  validates :notes, length: { maximum: 500 }
  validates :time_zone, inclusion: { in: TIME_ZONES }
  validates :title, length: { maximum: 120 }
  validate :ends_after_start
  validate :duration_is_bounded
  validate :does_not_overlap

  def localized_start
    starts_at.in_time_zone(time_zone)
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at ends_at id location starts_at time_zone title updated_at]
  end

  private

  def does_not_overlap
    return unless admin_user && starts_at && ends_at && ends_at > starts_at

    conflict = admin_user.schedule_events.where.not(id:).overlapping(starts_at, ends_at).chronological.first
    errors.add(:base, "overlaps #{conflict.title}") if conflict
  end

  def duration_is_bounded
    return unless starts_at && ends_at && ends_at > starts_at

    errors.add(:ends_at, "must be within 12 hours of the start") if ends_at - starts_at > MAXIMUM_DURATION
  end

  def ends_after_start
    return unless starts_at && ends_at

    errors.add(:ends_at, "must be after the start") unless ends_at > starts_at
  end
end
