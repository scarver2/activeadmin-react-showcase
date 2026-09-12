# db/migrate/20260907350000_create_activity_notifications.rb
# frozen_string_literal: true

class CreateActivityNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_notifications do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :body, null: false
      table.string :deep_link, null: false
      table.string :kind, null: false
      table.datetime :occurred_at, null: false
      table.datetime :read_at
      table.integer :sequence, null: false
      table.string :subject, null: false
      table.timestamps
    end

    add_index :activity_notifications, %i[admin_user_id sequence], unique: true
    add_index :activity_notifications, %i[admin_user_id occurred_at]
  end
end
