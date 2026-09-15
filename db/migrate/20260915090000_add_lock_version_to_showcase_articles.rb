# db/migrate/20260915090000_add_lock_version_to_showcase_articles.rb
# frozen_string_literal: true

class AddLockVersionToShowcaseArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :showcase_articles, :lock_version, :integer, default: 0, null: false
  end
end
