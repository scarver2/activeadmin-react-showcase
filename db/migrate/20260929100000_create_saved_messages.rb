# db/migrate/20260929100000_create_saved_messages.rb
# frozen_string_literal: true

class CreateSavedMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_messages do |table|
      table.references :chat_room, null: false
      table.references :membership, null: false
      table.references :message, null: false
      table.timestamps
    end

    add_index :saved_messages,
              %i[membership_id message_id],
              unique: true,
              name: "index_saved_messages_on_membership_and_message"
    add_index :saved_messages,
              %i[membership_id created_at],
              name: "index_saved_messages_on_membership_and_created_at"
    add_foreign_key :saved_messages,
                    :chat_messages,
                    column: %i[message_id chat_room_id],
                    on_delete: :cascade,
                    primary_key: %i[id chat_room_id],
                    name: "saved_messages_message_room_fk"
    add_foreign_key :saved_messages,
                    :chat_participants,
                    column: %i[membership_id chat_room_id],
                    on_delete: :cascade,
                    primary_key: %i[id chat_room_id],
                    name: "saved_messages_membership_room_fk"
  end
end
