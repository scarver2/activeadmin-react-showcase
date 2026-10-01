# db/migrate/20260929210001_create_showcase_article_documents.rb
# frozen_string_literal: true

class CreateShowcaseArticleDocuments < ActiveRecord::Migration[8.1]
  FTS_COLUMNS = [ "title", "summary", "tokenize='trigram'" ].freeze

  def up
    create_table :showcase_article_documents do |t|
      t.string :showcase_article_id, null: false
    end
    add_index :showcase_article_documents, :showcase_article_id, unique: true

    create_virtual_table :showcase_article_documents_fts, :fts5, FTS_COLUMNS
  end

  def down
    drop_virtual_table :showcase_article_documents_fts, :fts5, FTS_COLUMNS
    drop_table :showcase_article_documents
  end
end
