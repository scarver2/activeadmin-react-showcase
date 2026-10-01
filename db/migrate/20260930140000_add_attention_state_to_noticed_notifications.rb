# db/migrate/20260930140000_add_attention_state_to_noticed_notifications.rb
# frozen_string_literal: true

class AddAttentionStateToNoticedNotifications < ActiveRecord::Migration[8.1]
  def change
    change_table :noticed_notifications, bulk: true do |table|
      table.string :attention_kind, default: "fyi", null: false
      table.datetime :dismissed_at
      table.integer :lock_version, default: 0, null: false
      table.string :priority, default: "normal", null: false
      table.datetime :snoozed_until
    end

    add_check_constraint :noticed_notifications,
                         "attention_kind IN ('fyi', 'requires_action')",
                         name: "noticed_notifications_attention_kind"
    add_check_constraint :noticed_notifications,
                         "priority IN ('normal', 'high')",
                         name: "noticed_notifications_priority"
    add_index :noticed_notifications,
              %i[recipient_type recipient_id dismissed_at snoozed_until read_at],
              name: "index_noticed_notifications_on_recipient_attention"
    add_index :noticed_notifications,
              %i[recipient_type recipient_id attention_kind priority],
              name: "index_noticed_notifications_on_recipient_kind_priority"
  end
end
