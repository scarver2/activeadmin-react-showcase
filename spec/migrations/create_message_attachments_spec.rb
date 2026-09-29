# spec/migrations/create_message_attachments_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260929110000_create_message_attachments")

RSpec.describe CreateMessageAttachments do
  it "enforces one attachment and same-conversation ownership at the database boundary" do
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "AttachmentMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "attachments.sqlite3"))
      connection = database_class.connection
      build_message_schema(connection)
      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)
      migration.suppress_messages { migration.migrate(:up) }

      insert_attachment(connection, public_id: "valid", room_id: 1)
      expect do
        insert_attachment(connection, public_id: "duplicate", room_id: 1)
      end.to raise_error(ActiveRecord::RecordNotUnique)
      expect do
        insert_attachment(connection, message_id: 2, public_id: "cross-room", room_id: 1)
      end.to raise_error(ActiveRecord::InvalidForeignKey)

    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def build_message_schema(connection)
    connection.create_table(:chat_rooms)
    connection.create_table(:chat_messages) { |table| table.references :chat_room, null: false }
    connection.add_index(:chat_messages, %i[id chat_room_id], unique: true)
    connection.execute("INSERT INTO chat_rooms (id) VALUES (1), (2)")
    connection.execute("INSERT INTO chat_messages (id, chat_room_id) VALUES (1, 1), (2, 2)")
  end

  def insert_attachment(connection, message_id: 1, public_id:, room_id:)
    timestamp = connection.quote(Time.current)
    connection.execute <<~SQL.squish
      INSERT INTO message_attachments (chat_room_id, message_id, public_id, created_at, updated_at)
      VALUES (#{room_id}, #{message_id}, #{connection.quote(public_id)}, #{timestamp}, #{timestamp})
    SQL
  end
end
