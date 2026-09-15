# app/services/image_editor/save.rb
# frozen_string_literal: true

module ImageEditor
  class Save
    ATTRIBUTES = %i[focal_x focal_y label region_height region_width region_x region_y].freeze
    BOOLEAN_EDIT_ATTRIBUTES = %w[flip_x flip_y grayscale sepia].freeze
    NUMERIC_EDIT_ATTRIBUTES = (ImageAnnotation::EDIT_SPECIFICATION_KEYS - BOOLEAN_EDIT_ATTRIBUTES).freeze

    def self.call(admin_user:, asset:, attributes:)
      raise ActiveRecord::RecordInvalid, asset unless asset.file.image?
      annotation = admin_user.image_annotations.find_or_initialize_by(showcase_asset: asset)
      annotation.assign_attributes(attributes.slice(*ATTRIBUTES).to_h)
      if attributes[:edit_specification]
        annotation.edit_specification = normalize_edit_specification(attributes[:edit_specification].to_h)
      end
      annotation.save!
      annotation
    end

    def self.normalize_edit_specification(raw)
      specification = raw.stringify_keys
      BOOLEAN_EDIT_ATTRIBUTES.each { |key| specification[key] = ActiveModel::Type::Boolean.new.cast(specification[key]) if specification.key?(key) }
      NUMERIC_EDIT_ATTRIBUTES.each { |key| specification[key] = numeric(specification[key]) if specification.key?(key) }
      specification
    end
    private_class_method :normalize_edit_specification

    def self.numeric(value)
      Float(value)
    rescue ArgumentError, TypeError
      value
    end
    private_class_method :numeric
  end
end
