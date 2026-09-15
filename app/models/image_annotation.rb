# app/models/image_annotation.rb
# frozen_string_literal: true

class ImageAnnotation < ApplicationRecord
  COORDINATES = %i[focal_x focal_y region_x region_y region_width region_height].freeze
  DEFAULT_EDIT_SPECIFICATION = {
    "brightness" => 1.0,
    "contrast" => 1.0,
    "crop_height" => 1.0,
    "crop_width" => 1.0,
    "crop_x" => 0.0,
    "crop_y" => 0.0,
    "flip_x" => false,
    "flip_y" => false,
    "grayscale" => false,
    "rotation" => 0,
    "saturation" => 1.0,
    "sepia" => false
  }.freeze
  EDIT_SPECIFICATION_KEYS = DEFAULT_EDIT_SPECIFICATION.keys.freeze
  FILTER_RANGES = {
    "brightness" => 0.5..1.5,
    "contrast" => 0.5..1.5,
    "saturation" => 0.0..2.0
  }.freeze

  belongs_to :admin_user
  belongs_to :showcase_asset

  validates :focal_x, :focal_y, numericality: { in: 0.0..1.0 }
  validates :label, inclusion: { in: %w[Logo Product Subject] }
  validates :region_x, :region_y, :region_width, :region_height, numericality: { in: 0.0..1.0 }, allow_nil: true
  validate :edit_specification_is_bounded
  validate :region_within_image
  validate :image_asset

  def canonical_edit_specification
    DEFAULT_EDIT_SPECIFICATION.merge((edit_specification || {}).stringify_keys).slice(*EDIT_SPECIFICATION_KEYS)
  end

  private

  def image_asset
    errors.add(:showcase_asset, "must be an image") unless showcase_asset&.file&.image?
  end

  def edit_specification_is_bounded
    specification = (edit_specification || {}).stringify_keys
    errors.add(:edit_specification, "contains unsupported instructions") if (specification.keys - EDIT_SPECIFICATION_KEYS).any?
    canonical = canonical_edit_specification
    FILTER_RANGES.each do |key, range|
      errors.add(:edit_specification, "has an invalid #{key}") unless range.cover?(numeric(canonical[key]))
    end
    validate_crop(canonical)
    errors.add(:edit_specification, "has an invalid rotation") unless [ 0, 90, 180, 270 ].include?(numeric(canonical["rotation"]))
    %w[flip_x flip_y grayscale sepia].each do |key|
      errors.add(:edit_specification, "has an invalid #{key}") unless [ true, false ].include?(canonical[key])
    end
  end

  def numeric(value)
    Float(value)
  rescue ArgumentError, TypeError
    Float::NAN
  end

  def validate_crop(specification)
    crop = %w[crop_x crop_y crop_width crop_height].to_h { |key| [ key, numeric(specification[key]) ] }
    errors.add(:edit_specification, "has an invalid crop") unless crop.values.all? { |value| value.finite? && value.between?(0.0, 1.0) }
    errors.add(:edit_specification, "crop must have positive dimensions") unless crop["crop_width"].positive? && crop["crop_height"].positive?
    return unless crop.values.all?(&:finite?)

    errors.add(:edit_specification, "crop must stay inside the image") if crop["crop_x"] + crop["crop_width"] > 1 || crop["crop_y"] + crop["crop_height"] > 1
  end

  def region_within_image
    return if [ region_x, region_y, region_width, region_height ].any?(&:nil?)
    errors.add(:base, "Annotation region must stay inside the image") if region_x + region_width > 1 || region_y + region_height > 1
  end
end
