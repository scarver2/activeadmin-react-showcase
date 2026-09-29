# db/migrate/20260928090000_promote_operator_chat_to_conversations.rb
# frozen_string_literal: true

class PromoteOperatorChatToConversations < ActiveRecord::Migration[8.1]
  def up
    add_column :chat_rooms, :last_activity_at, :datetime
    add_column :chat_rooms, :topic, :string
    add_reference :chat_participants, :admin_user, foreign_key: true
    add_reference :chat_participants, :last_read_message
    add_column :chat_participants, :last_read_at, :datetime
    add_column :chat_participants, :legacy_identity, :boolean, default: true, null: false
    add_column :chat_messages, :public_id, :string

    execute <<~SQL.squish
      UPDATE chat_messages
      SET public_id = 'message-' || id
    SQL
    execute <<~SQL.squish
      UPDATE chat_rooms
      SET last_activity_at = COALESCE(
        (SELECT MAX(chat_messages.created_at) FROM chat_messages WHERE chat_messages.chat_room_id = chat_rooms.id),
        chat_rooms.updated_at
      )
    SQL
    execute <<~SQL.squish
      UPDATE chat_participants
      SET legacy_identity = TRUE
    SQL

    remove_foreign_key :chat_messages, column: :author_id

    add_index :chat_participants,
              %i[chat_room_id admin_user_id],
              unique: true,
              where: "admin_user_id IS NOT NULL"
    add_index :chat_participants, %i[id chat_room_id], unique: true
    add_index :chat_messages, %i[id chat_room_id], unique: true
    add_index :chat_messages, :public_id, unique: true
    add_index :chat_rooms, %i[last_activity_at id]
    add_foreign_key :chat_messages,
                    :chat_participants,
                    column: %i[author_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "chat_messages_participant_room_fk"
    add_foreign_key :chat_participants,
                    :chat_messages,
                    column: %i[last_read_message_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "chat_participants_read_cursor_fk"
    add_check_constraint :chat_rooms,
                         "topic IS NULL OR length(topic) BETWEEN 1 AND 160",
                         name: "chat_rooms_topic_length"
    add_check_constraint :chat_messages,
                         "sequence > 0",
                         name: "chat_messages_positive_sequence"
    add_check_constraint :chat_participants,
                         <<~SQL.squish,
                           (legacy_identity = TRUE AND admin_user_id IS NULL)
                           OR (legacy_identity = FALSE AND admin_user_id IS NOT NULL)
                         SQL
                         name: "chat_participants_identity_authority"
    create_sqlite_rolling_triggers
  end

  def down
    drop_sqlite_rolling_triggers
    remove_check_constraint :chat_participants, name: "chat_participants_identity_authority"
    remove_check_constraint :chat_messages, name: "chat_messages_positive_sequence"
    remove_check_constraint :chat_rooms, name: "chat_rooms_topic_length"
    remove_foreign_key :chat_participants, column: %i[last_read_message_id chat_room_id]
    remove_foreign_key :chat_messages, column: %i[author_id chat_room_id]
    remove_index :chat_rooms, column: %i[last_activity_at id]
    remove_index :chat_participants, column: %i[chat_room_id admin_user_id]

    remove_column :chat_participants, :last_read_at
    remove_reference :chat_participants, :last_read_message
    remove_reference :chat_participants, :admin_user, foreign_key: true
    remove_column :chat_participants, :legacy_identity
    remove_index :chat_messages, column: %i[id chat_room_id]
    remove_index :chat_messages, :public_id
    remove_column :chat_messages, :public_id
    remove_index :chat_participants, column: %i[id chat_room_id]
    remove_column :chat_rooms, :topic
    remove_column :chat_rooms, :last_activity_at

    add_foreign_key :chat_messages, :chat_participants, column: :author_id
  end

  private

  def create_sqlite_rolling_triggers
    return unless connection.adapter_name == "SQLite"

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

  def drop_sqlite_rolling_triggers
    return unless connection.adapter_name == "SQLite"

    execute "DROP TRIGGER IF EXISTS chat_messages_advance_room_activity"
    execute "DROP TRIGGER IF EXISTS chat_messages_fill_public_id"
  end
end
