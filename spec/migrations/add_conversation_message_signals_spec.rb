# spec/migrations/add_conversation_message_signals_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260928120000_add_conversation_message_signals")

RSpec.describe AddConversationMessageSignals do
  it "preserves the prior release's SQLite rolling-write triggers across table rebuilds" do
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "SignalsMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "rolling.sqlite3"))
      connection = database_class.connection
      build_prior_release_schema(connection)

      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)
      migration.suppress_messages { migration.up }

      expect(rolling_trigger_names(connection)).to contain_exactly(
        "chat_messages_advance_room_activity",
        "chat_messages_fill_public_id"
      )

      insert_prior_release_message(connection)
      expect(connection.select_value("SELECT public_id FROM chat_messages WHERE id = 3")).to eq("message-3")
      expect(connection.select_value("SELECT last_activity_at FROM chat_rooms WHERE id = 1")).to eq("2026-09-29 00:00:00")
    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def build_prior_release_schema(connection)
    connection.create_table(:chat_rooms) do |table|
      table.datetime :last_activity_at
    end
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
    create_prior_release_triggers(connection)
  end

  def create_prior_release_triggers(connection)
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
        UPDATE chat_rooms SET last_activity_at = NEW.created_at WHERE id = NEW.chat_room_id;
      END;
    SQL
  end

  def insert_prior_release_message(connection)
    timestamp = connection.quote("2026-09-29 00:00:00")
    connection.execute("INSERT INTO chat_rooms (id) VALUES (1)")
    connection.execute("INSERT INTO chat_participants (id, chat_room_id) VALUES (2, 1)")
    connection.execute <<~SQL.squish
      INSERT INTO chat_messages (id, author_id, body, chat_room_id, sequence, created_at, updated_at)
      VALUES (3, 2, 'Prior release write', 1, 1, #{timestamp}, #{timestamp})
    SQL
  end

  def rolling_trigger_names(connection)
    connection.select_values(<<~SQL.squish)
      SELECT name
      FROM sqlite_master
      WHERE type = 'trigger' AND name LIKE 'chat_messages_%'
      ORDER BY name
    SQL
  end
end
