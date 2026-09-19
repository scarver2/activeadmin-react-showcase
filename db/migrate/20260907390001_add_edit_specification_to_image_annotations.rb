# db/migrate/20260907390001_add_edit_specification_to_image_annotations.rb
# frozen_string_literal: true

class AddEditSpecificationToImageAnnotations < ActiveRecord::Migration[8.1]
  def change
    add_column :image_annotations, :edit_specification, :json, null: false, default: {
      brightness: 1.0,
      contrast: 1.0,
      crop_height: 1.0,
      crop_width: 1.0,
      crop_x: 0.0,
      crop_y: 0.0,
      flip_x: false,
      flip_y: false,
      grayscale: false,
      rotation: 0,
      saturation: 1.0,
      sepia: false
    }
  end
end
