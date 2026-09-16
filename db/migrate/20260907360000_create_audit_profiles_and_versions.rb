# db/migrate/20260907360000_create_audit_profiles_and_versions.rb
# frozen_string_literal: true

class CreateAuditProfilesAndVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_profiles do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :name, null: false
      table.string :plan, null: false
      table.text :preferences, null: false, default: "{}"
      table.timestamps
    end

    create_table :versions do |table|
      table.string :whodunnit
      table.string :item_type, null: false
      table.integer :item_id, null: false
      table.string :event, null: false
      table.text :object
      table.text :object_changes
      table.datetime :created_at
    end
    add_index :versions, %i[item_type item_id]
  end
end
