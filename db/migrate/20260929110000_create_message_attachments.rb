# db/migrate/20260929110000_create_message_attachments.rb
# frozen_string_literal: true

class CreateMessageAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :message_attachments do |table|
      table.references :chat_room, null: false
      table.references :message, index: { unique: true }, null: false
      table.string :public_id, null: false
      table.timestamps
    end

    add_index :message_attachments, :public_id, unique: true
    add_foreign_key :message_attachments,
                    :chat_messages,
                    column: %i[message_id chat_room_id],
                    primary_key: %i[id chat_room_id],
                    name: "message_attachments_message_room_fk"
  end
end
