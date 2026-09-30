# db/migrate/20260929210000_create_account_documents.rb
# frozen_string_literal: true

class CreateAccountDocuments < ActiveRecord::Migration[8.1]
  FTS_COLUMNS = [ "name", "tokenize='trigram'" ].freeze

  def up
    create_table :account_documents do |t|
      t.string :account_id, null: false
    end
    add_index :account_documents, :account_id, unique: true

    create_virtual_table :account_documents_fts, :fts5, FTS_COLUMNS
  end

  def down
    drop_virtual_table :account_documents_fts, :fts5, FTS_COLUMNS
    drop_table :account_documents
  end
end
