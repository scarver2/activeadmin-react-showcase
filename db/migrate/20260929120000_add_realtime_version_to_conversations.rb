# db/migrate/20260929120000_add_realtime_version_to_conversations.rb
# frozen_string_literal: true

class AddRealtimeVersionToConversations < ActiveRecord::Migration[8.1]
  def up
    add_column :chat_rooms, :realtime_version, :integer, default: 0, null: false
    add_check_constraint :chat_rooms,
                         "realtime_version >= 0",
                         name: "chat_rooms_realtime_version_nonnegative"
  end

  def down
    remove_check_constraint :chat_rooms, name: "chat_rooms_realtime_version_nonnegative"
    remove_column :chat_rooms, :realtime_version
  end
end
