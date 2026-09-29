# spec/migrations/create_message_attachments_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260929110000_create_message_attachments")

RSpec.describe CreateMessageAttachments do
  it "enforces ownership while preserving accepted rolling triggers through exact up and down migration" do
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "AttachmentMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "attachments.sqlite3"))
      connection = database_class.connection
      build_message_schema(connection)
      accepted_triggers = rolling_trigger_definitions(connection)
      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)
      migration.suppress_messages { migration.migrate(:up) }
      expect(rolling_trigger_definitions(connection)).to eq(accepted_triggers)

      insert_attachment(connection, public_id: "valid", room_id: 1)
      expect do
        insert_attachment(connection, public_id: "duplicate", room_id: 1)
      end.to raise_error(ActiveRecord::RecordNotUnique)
      expect do
        insert_attachment(connection, message_id: 2, public_id: "cross-room", room_id: 1)
      end.to raise_error(ActiveRecord::InvalidForeignKey)

      migration.suppress_messages { migration.migrate(:down) }
      expect(connection.table_exists?(:message_attachments)).to be(false)
      expect(rolling_trigger_definitions(connection)).to eq(accepted_triggers)

    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def build_message_schema(connection)
    connection.create_table(:chat_rooms)
    connection.create_table(:chat_messages) do |table|
      table.references :chat_room, null: false
      table.string :public_id
    end
    connection.add_index(:chat_messages, %i[id chat_room_id], unique: true)
    connection.execute("INSERT INTO chat_rooms (id) VALUES (1), (2)")
    connection.execute("INSERT INTO chat_messages (id, chat_room_id) VALUES (1, 1), (2, 2)")
    create_accepted_triggers(connection)
  end

  def create_accepted_triggers(connection)
    connection.execute <<~SQL
      CREATE TRIGGER chat_messages_fill_public_id
      AFTER INSERT ON chat_messages
      WHEN NEW.public_id IS NULL
      BEGIN
        UPDATE chat_messages SET public_id = 'message-' || NEW.id WHERE id = NEW.id;
      END;
    SQL
    connection.execute <<~SQL
      CREATE TRIGGER chat_messages_advance_room_activity
      AFTER INSERT ON chat_messages
      BEGIN
        UPDATE chat_rooms SET id = id WHERE id = NEW.chat_room_id;
      END;
    SQL
  end

  def insert_attachment(connection, message_id: 1, public_id:, room_id:)
    timestamp = connection.quote(Time.current)
    connection.execute <<~SQL.squish
      INSERT INTO message_attachments (chat_room_id, message_id, public_id, created_at, updated_at)
      VALUES (#{room_id}, #{message_id}, #{connection.quote(public_id)}, #{timestamp}, #{timestamp})
    SQL
  end

  def rolling_trigger_definitions(connection)
    connection.select_rows(<<~SQL.squish)
      SELECT name, sql
      FROM sqlite_master
      WHERE type = 'trigger' AND name LIKE 'chat_messages_%'
      ORDER BY name
    SQL
  end
end
