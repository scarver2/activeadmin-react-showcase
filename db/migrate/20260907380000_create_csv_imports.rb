# db/migrate/20260907380000_create_csv_imports.rb
# frozen_string_literal: true

class CreateCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :csv_imports do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.datetime :confirmed_at
      table.text :errors_json, null: false, default: "[]"
      table.integer :failed_rows, null: false, default: 0
      table.integer :imported_rows, null: false, default: 0
      table.text :mappings_json, null: false, default: "{}"
      table.integer :processed_rows, null: false, default: 0
      table.integer :row_count, null: false, default: 0
      table.string :status, null: false, default: "draft"
      table.string :token, null: false
      table.timestamps
    end
    add_index :csv_imports, :token, unique: true

    create_table :csv_import_rows do |table|
      table.references :contact, foreign_key: true
      table.references :csv_import, null: false, foreign_key: true
      table.text :error
      table.integer :row_number, null: false
      table.string :status, null: false, default: "pending"
      table.timestamps
    end
    add_index :csv_import_rows, %i[csv_import_id row_number], unique: true
  end
end
