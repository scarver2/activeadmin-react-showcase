# db/migrate/20260907390000_create_image_annotations.rb
# frozen_string_literal: true

class CreateImageAnnotations < ActiveRecord::Migration[8.1]
  def change
    create_table :image_annotations do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.references :showcase_asset, null: false, foreign_key: true
      table.decimal :focal_x, precision: 6, scale: 5, null: false, default: 0.5
      table.decimal :focal_y, precision: 6, scale: 5, null: false, default: 0.5
      table.decimal :region_x, precision: 6, scale: 5
      table.decimal :region_y, precision: 6, scale: 5
      table.decimal :region_width, precision: 6, scale: 5
      table.decimal :region_height, precision: 6, scale: 5
      table.string :label, null: false, default: "Subject"
      table.timestamps
    end
    add_index :image_annotations, %i[admin_user_id showcase_asset_id], unique: true
  end
end
