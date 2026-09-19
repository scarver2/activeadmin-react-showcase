# db/migrate/20260907420000_create_preview_messages.rb
# frozen_string_literal: true

class CreatePreviewMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :preview_messages do |table|
      table.string :recipient, null: false
      table.string :sender, null: false
      table.string :subject, null: false
      table.text :html_body, null: false
      table.text :text_body, null: false
      table.timestamps
    end
  end
end
