# db/migrate/20260923090000_create_ckeditor_articles.rb
# frozen_string_literal: true

class CreateCkeditorArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :ckeditor_articles do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :title, null: false
      table.string :summary
      table.text :body_html, null: false
      table.integer :lock_version, null: false, default: 0

      table.timestamps
    end

    add_index :ckeditor_articles, %i[admin_user_id title]
  end
end
