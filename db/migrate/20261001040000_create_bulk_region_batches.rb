# db/migrate/20261001040000_create_bulk_region_batches.rb
# frozen_string_literal: true

class CreateBulkRegionBatches < ActiveRecord::Migration[8.1]
  def up
    create_table :bulk_region_batches do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :region, null: false
      table.string :state, null: false, default: "preview"
      table.json :selection, null: false, default: []
      table.json :results, null: false, default: {}
      table.timestamps
    end
  end

  def down
    drop_table :bulk_region_batches
  end
end
