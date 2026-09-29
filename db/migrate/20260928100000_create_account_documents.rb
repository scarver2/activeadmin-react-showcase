# db/migrate/20260928100000_create_account_documents.rb
# frozen_string_literal: true

class CreateAccountDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :account_documents do |t|
      t.string :account_id, null: false
    end
    add_index :account_documents, :account_id, unique: true

    create_virtual_table :account_documents_fts, :fts5, [ "name", "tokenize='trigram'" ]
  end
end
