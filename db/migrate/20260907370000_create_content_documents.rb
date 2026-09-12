# db/migrate/20260907370000_create_content_documents.rb
# frozen_string_literal: true

class CreateContentDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :content_documents do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.integer :lock_version, null: false, default: 0
      table.string :title, null: false
      table.timestamps
    end
    create_table :content_blocks do |table|
      table.references :content_document, null: false, foreign_key: { on_delete: :cascade }
      table.string :block_type, null: false
      table.text :body, null: false
      table.integer :position, null: false
      table.timestamps
      table.index %i[content_document_id position], unique: true
    end
  end
end
