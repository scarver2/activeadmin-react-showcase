# spec/migrations/create_saved_messages_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260929100000_create_saved_messages")

RSpec.describe CreateSavedMessages do
  it "preserves the accepted SQLite rolling triggers through exact up and down migration" do
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "SavedMessagesMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "rolling.sqlite3"))
      connection = database_class.connection
      build_accepted_schema(connection)
      accepted_triggers = rolling_trigger_definitions(connection)
      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)

      migration.suppress_messages { migration.up }
      expect(connection.table_exists?(:saved_messages)).to be(true)
      expect(rolling_trigger_definitions(connection)).to eq(accepted_triggers)
      insert_message(connection, id: 3, sequence: 1, timestamp: "2026-09-29 00:00:00")
      expect_trigger_effects(connection, id: 3, timestamp: "2026-09-29 00:00:00")

      migration.suppress_messages { migration.down }
      expect(connection.table_exists?(:saved_messages)).to be(false)
      expect(rolling_trigger_definitions(connection)).to eq(accepted_triggers)
      insert_message(connection, id: 4, sequence: 2, timestamp: "2026-09-29 00:01:00")
      expect_trigger_effects(connection, id: 4, timestamp: "2026-09-29 00:01:00")
    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def build_accepted_schema(connection)
    connection.create_table(:chat_rooms) { |table| table.datetime :last_activity_at }
    connection.create_table(:chat_participants) { |table| table.references :chat_room, null: false }
    connection.create_table(:chat_messages) do |table|
      table.references :chat_room, null: false
      table.references :author, null: false
      table.string :body, null: false
      table.string :public_id
      table.integer :sequence, null: false
      table.timestamps
    end
    connection.add_index(:chat_messages, %i[id chat_room_id], unique: true)
    connection.add_index(:chat_participants, %i[id chat_room_id], unique: true)
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
        UPDATE chat_rooms
        SET last_activity_at = CASE
          WHEN last_activity_at IS NULL OR last_activity_at < NEW.created_at THEN NEW.created_at
          ELSE last_activity_at
        END
        WHERE id = NEW.chat_room_id;
      END;
    SQL
  end

  def insert_message(connection, id:, sequence:, timestamp:)
    quoted_timestamp = connection.quote(timestamp)
    connection.execute("INSERT OR IGNORE INTO chat_rooms (id) VALUES (1)")
    connection.execute("INSERT OR IGNORE INTO chat_participants (id, chat_room_id) VALUES (2, 1)")
    connection.execute <<~SQL.squish
      INSERT INTO chat_messages (id, author_id, body, chat_room_id, sequence, created_at, updated_at)
      VALUES (#{id}, 2, 'Rolling write', 1, #{sequence}, #{quoted_timestamp}, #{quoted_timestamp})
    SQL
  end

  def expect_trigger_effects(connection, id:, timestamp:)
    expect(connection.select_value("SELECT public_id FROM chat_messages WHERE id = #{id}")).to eq("message-#{id}")
    expect(connection.select_value("SELECT last_activity_at FROM chat_rooms WHERE id = 1")).to eq(timestamp)
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
