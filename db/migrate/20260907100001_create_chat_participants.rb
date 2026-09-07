# db/migrate/20260907100001_create_chat_participants.rb
# frozen_string_literal: true

class CreateChatParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_participants do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.string :display_name, null: false
      t.string :key, null: false
      t.timestamps
    end

    add_index :chat_participants, %i[chat_room_id key], unique: true
  end
end
