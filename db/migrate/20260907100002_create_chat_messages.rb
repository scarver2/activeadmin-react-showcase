# db/migrate/20260907100002_create_chat_messages.rb
# frozen_string_literal: true

class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :author, null: false, foreign_key: { to_table: :chat_participants }
      t.references :chat_room, null: false, foreign_key: true
      t.text :body, null: false
      t.integer :sequence, null: false
      t.timestamps
    end

    add_index :chat_messages, %i[chat_room_id sequence], unique: true
    add_check_constraint :chat_messages, "length(body) BETWEEN 1 AND 500", name: "chat_messages_body_length"
  end
end
