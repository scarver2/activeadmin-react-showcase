# db/migrate/20260928120000_add_conversation_message_signals.rb
# frozen_string_literal: true

class AddConversationMessageSignals < ActiveRecord::Migration[8.1]
  DISPOSITION_KINDS = %w[like dislike question].freeze

  def up
    add_reference :chat_messages, :reply_to_message
    add_foreign_key :chat_messages,
                    :chat_messages,
                    column: %i[reply_to_message_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "chat_messages_reply_room_fk"

    create_table :message_dispositions do |table|
      table.references :chat_room, null: false
      table.references :message, null: false
      table.references :membership, null: false
      table.string :kind, null: false
      table.timestamps
    end
    add_index :message_dispositions,
              %i[message_id membership_id],
              unique: true,
              name: "index_message_dispositions_on_message_and_membership"
    add_check_constraint :message_dispositions,
                         "kind IN ('like', 'dislike', 'question')",
                         name: "message_dispositions_kind"
    add_foreign_key :message_dispositions,
                    :chat_messages,
                    column: %i[message_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "message_dispositions_message_room_fk"
    add_foreign_key :message_dispositions,
                    :chat_participants,
                    column: %i[membership_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "message_dispositions_membership_room_fk"

    create_table :message_mentions do |table|
      table.references :chat_room, null: false
      table.references :message, null: false
      table.references :mentioned_membership, null: false
      table.string :mention_text, null: false
      table.timestamps
    end
    add_index :message_mentions,
              %i[message_id mentioned_membership_id],
              unique: true,
              name: "index_message_mentions_on_message_and_membership"
    add_check_constraint :message_mentions,
                         "length(mention_text) BETWEEN 2 AND 81",
                         name: "message_mentions_text_length"
    add_foreign_key :message_mentions,
                    :chat_messages,
                    column: %i[message_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "message_mentions_message_room_fk"
    add_foreign_key :message_mentions,
                    :chat_participants,
                    column: %i[mentioned_membership_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "message_mentions_membership_room_fk"
    create_sqlite_rolling_triggers
  end

  def down
    drop_table :message_mentions
    drop_table :message_dispositions
    remove_foreign_key :chat_messages, name: "chat_messages_reply_room_fk"
    remove_reference :chat_messages, :reply_to_message
    create_sqlite_rolling_triggers
  end

  private

  def create_sqlite_rolling_triggers
    return unless connection.adapter_name == "SQLite"

    execute "DROP TRIGGER IF EXISTS chat_messages_advance_room_activity"
    execute "DROP TRIGGER IF EXISTS chat_messages_fill_public_id"
    execute <<~SQL
      CREATE TRIGGER chat_messages_fill_public_id
      AFTER INSERT ON chat_messages
      WHEN NEW.public_id IS NULL
      BEGIN
        UPDATE chat_messages
        SET public_id = 'message-' || NEW.id
        WHERE id = NEW.id;
      END;
    SQL
    execute <<~SQL
      CREATE TRIGGER chat_messages_advance_room_activity
      AFTER INSERT ON chat_messages
      BEGIN
        UPDATE chat_rooms
        SET last_activity_at = CASE
          WHEN last_activity_at IS NULL OR last_activity_at < NEW.created_at THEN NEW.created_at
          ELSE last_activity_at
        END
        WHERE id = NEW.chat_room_id;
      END;
    SQL
  end
end
