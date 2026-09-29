# db/migrate/20260928100001_create_showcase_article_documents.rb
# frozen_string_literal: true

class CreateShowcaseArticleDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :showcase_article_documents do |t|
      t.string :showcase_article_id, null: false
    end
    add_index :showcase_article_documents, :showcase_article_id, unique: true

    create_virtual_table :showcase_article_documents_fts, :fts5, [ "title", "summary", "tokenize='trigram'" ]
  end
end
