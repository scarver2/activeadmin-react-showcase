# db/migrate/20260928090000_promote_operator_chat_to_conversations.rb
# frozen_string_literal: true

class PromoteOperatorChatToConversations < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :chat_messages, name: "chat_messages_body_length"

    rename_table :chat_rooms, :conversations
    rename_column :conversations, :name, :title

    rename_table :chat_participants, :conversation_memberships
    rename_column :conversation_memberships, :chat_room_id, :conversation_id

    rename_table :chat_messages, :messages
    rename_column :messages, :author_id, :conversation_membership_id
    rename_column :messages, :chat_room_id, :conversation_id
    remove_foreign_key :messages, column: :conversation_membership_id

    add_column :conversations, :last_activity_at, :datetime
    add_column :conversations, :topic, :string
    add_reference :conversation_memberships, :admin_user, foreign_key: true
    add_reference :conversation_memberships, :last_read_message
    add_column :conversation_memberships, :last_read_at, :datetime
    add_column :conversation_memberships, :legacy_identity, :boolean, default: false, null: false
    add_column :messages, :public_id, :string

    execute <<~SQL.squish
      UPDATE messages
      SET public_id = 'message-' || id
    SQL
    execute <<~SQL.squish
      UPDATE conversations
      SET last_activity_at = COALESCE(
        (SELECT MAX(messages.created_at) FROM messages WHERE messages.conversation_id = conversations.id),
        conversations.updated_at
      )
    SQL
    execute <<~SQL.squish
      UPDATE conversation_memberships
      SET legacy_identity = TRUE
    SQL

    change_column_null :conversations, :last_activity_at, false
    change_column_null :messages, :public_id, false

    add_index :conversation_memberships,
              %i[conversation_id admin_user_id],
              unique: true,
              where: "admin_user_id IS NOT NULL"
    add_index :messages, :public_id, unique: true
    add_index :messages, %i[id conversation_id], unique: true
    add_index :conversation_memberships, %i[id conversation_id], unique: true
    add_index :conversations, %i[last_activity_at id]
    add_foreign_key :messages,
                    :conversation_memberships,
                    column: %i[conversation_membership_id conversation_id],
                    primary_key: %i[id conversation_id],
                    name: "messages_conversation_membership_fk"
    add_foreign_key :conversation_memberships,
                    :messages,
                    column: %i[last_read_message_id conversation_id],
                    primary_key: %i[id conversation_id],
                    name: "conversation_memberships_read_cursor_fk"
    add_check_constraint :conversations,
                         "length(title) BETWEEN 1 AND 120",
                         name: "conversations_title_length"
    add_check_constraint :conversations,
                         "topic IS NULL OR length(topic) BETWEEN 1 AND 160",
                         name: "conversations_topic_length"
    add_check_constraint :messages,
                         "length(body) BETWEEN 1 AND 500",
                         name: "messages_body_length"
    add_check_constraint :messages,
                         "sequence > 0",
                         name: "messages_positive_sequence"
    add_check_constraint :conversation_memberships,
                         <<~SQL.squish,
                           (legacy_identity = TRUE AND admin_user_id IS NULL)
                           OR (legacy_identity = FALSE AND admin_user_id IS NOT NULL)
                         SQL
                         name: "conversation_memberships_identity_authority"
  end

  def down
    remove_check_constraint :conversation_memberships, name: "conversation_memberships_identity_authority"
    remove_check_constraint :messages, name: "messages_positive_sequence"
    remove_check_constraint :messages, name: "messages_body_length"
    remove_check_constraint :conversations, name: "conversations_topic_length"
    remove_check_constraint :conversations, name: "conversations_title_length"
    remove_foreign_key :conversation_memberships, column: %i[last_read_message_id conversation_id]
    remove_foreign_key :messages, column: %i[conversation_membership_id conversation_id]
    remove_index :conversations, column: %i[last_activity_at id]
    remove_index :conversation_memberships, column: %i[conversation_id admin_user_id]

    remove_column :conversation_memberships, :last_read_at
    remove_reference :conversation_memberships, :last_read_message
    remove_reference :conversation_memberships, :admin_user, foreign_key: true
    remove_column :conversation_memberships, :legacy_identity
    remove_index :messages, column: %i[id conversation_id]
    remove_index :messages, :public_id
    remove_column :messages, :public_id
    remove_column :conversations, :topic
    remove_column :conversations, :last_activity_at

    add_foreign_key :messages, :conversation_memberships, column: :conversation_membership_id
    remove_index :conversation_memberships, column: %i[id conversation_id]

    rename_column :messages, :conversation_id, :chat_room_id
    rename_column :messages, :conversation_membership_id, :author_id
    rename_table :messages, :chat_messages

    rename_column :conversation_memberships, :conversation_id, :chat_room_id
    rename_table :conversation_memberships, :chat_participants

    rename_column :conversations, :title, :name
    rename_table :conversations, :chat_rooms

    add_check_constraint :chat_messages,
                         "length(body) BETWEEN 1 AND 500",
                         name: "chat_messages_body_length"
  end
end
