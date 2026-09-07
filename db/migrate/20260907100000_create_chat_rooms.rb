# db/migrate/20260907100000_create_chat_rooms.rb
# frozen_string_literal: true

class CreateChatRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_rooms do |t|
      t.string :name, null: false
      t.string :public_id, null: false
      t.timestamps
    end

    add_index :chat_rooms, :public_id, unique: true
  end
end
