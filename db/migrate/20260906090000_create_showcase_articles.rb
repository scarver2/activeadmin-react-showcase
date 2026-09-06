# db/migrate/20260906090000_create_showcase_articles.rb
# frozen_string_literal: true

class CreateShowcaseArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :showcase_articles do |table|
      table.text :editor_state, null: false
      table.text :rendered_html, null: false
      table.string :summary
      table.string :title, null: false
      table.timestamps

      table.index :title
    end
  end
end
