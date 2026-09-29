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
  end

  def down
    drop_table :message_mentions
    drop_table :message_dispositions
    remove_foreign_key :chat_messages, name: "chat_messages_reply_room_fk"
    remove_reference :chat_messages, :reply_to_message
  end
end
