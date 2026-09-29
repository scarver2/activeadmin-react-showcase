# db/migrate/20260928130000_create_scheduled_messages.rb
# frozen_string_literal: true

class CreateScheduledMessages < ActiveRecord::Migration[8.1]
  STATES = %w[pending delivered cancelled failed].freeze

  def up
    create_table :scheduled_messages do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.references :chat_room, null: false, foreign_key: true
      table.text :body, null: false
      table.datetime :scheduled_for, null: false
      table.string :state, null: false, default: "pending"
      table.string :public_id, null: false
      table.string :delivery_public_id, null: false
      table.references :delivered_message, index: { unique: true }
      table.datetime :delivered_at
      table.datetime :cancelled_at
      table.datetime :failed_at
      table.string :failure_code
      table.string :failure_detail
      table.integer :attempt_count, null: false, default: 0
      table.datetime :last_attempted_at
      table.timestamps
    end

    add_index :scheduled_messages, :public_id, unique: true
    add_index :scheduled_messages, :delivery_public_id, unique: true
    add_index :scheduled_messages,
              %i[admin_user_id state scheduled_for],
              name: "index_scheduled_messages_on_author_state_and_time"
    add_check_constraint :scheduled_messages,
                         "length(body) BETWEEN 1 AND 500",
                         name: "scheduled_messages_body_length"
    add_check_constraint :scheduled_messages,
                         "state IN ('pending', 'delivered', 'cancelled', 'failed')",
                         name: "scheduled_messages_state"
    add_check_constraint :scheduled_messages,
                         "attempt_count >= 0",
                         name: "scheduled_messages_attempt_count"
    add_check_constraint :scheduled_messages,
                         "state != 'delivered' OR (delivered_message_id IS NOT NULL AND delivered_at IS NOT NULL)",
                         name: "scheduled_messages_delivered_state"
    add_check_constraint :scheduled_messages,
                         "state != 'cancelled' OR cancelled_at IS NOT NULL",
                         name: "scheduled_messages_cancelled_state"
    add_check_constraint :scheduled_messages,
                         "state != 'failed' OR (failed_at IS NOT NULL AND failure_code IS NOT NULL)",
                         name: "scheduled_messages_failed_state"
    add_foreign_key :scheduled_messages,
                    :chat_messages,
                    column: %i[delivered_message_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "scheduled_messages_delivery_room_fk"
  end

  def down
    drop_table :scheduled_messages
  end
end
