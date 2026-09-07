# db/migrate/20260907200001_create_showcase_assets.rb
# frozen_string_literal: true

class CreateShowcaseAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :showcase_assets do |t|
      t.string :title, null: false
      t.timestamps
    end

    add_index :showcase_assets, :title
  end
end
