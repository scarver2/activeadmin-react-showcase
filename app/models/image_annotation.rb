# app/models/image_annotation.rb
# frozen_string_literal: true

class ImageAnnotation < ApplicationRecord
  COORDINATES = %i[focal_x focal_y region_x region_y region_width region_height].freeze

  belongs_to :admin_user
  belongs_to :showcase_asset

  validates :focal_x, :focal_y, numericality: { in: 0.0..1.0 }
  validates :label, inclusion: { in: %w[Logo Product Subject] }
  validates :region_x, :region_y, :region_width, :region_height, numericality: { in: 0.0..1.0 }, allow_nil: true
  validate :region_within_image
  validate :image_asset

  private

  def image_asset
    errors.add(:showcase_asset, "must be an image") unless showcase_asset&.file&.image?
  end

  def region_within_image
    return if [ region_x, region_y, region_width, region_height ].any?(&:nil?)
    errors.add(:base, "Annotation region must stay inside the image") if region_x + region_width > 1 || region_y + region_height > 1
  end
end
