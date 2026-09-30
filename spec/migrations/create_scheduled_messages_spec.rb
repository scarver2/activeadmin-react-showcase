# spec/migrations/create_scheduled_messages_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260928130000_create_scheduled_messages")

RSpec.describe CreateScheduledMessages do
  it "leaves the accepted SQLite rolling-write triggers intact on migrate and rollback" do
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "ScheduledMessagesMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "rolling.sqlite3"))
      connection = database_class.connection
      build_prior_release_schema(connection)
      trigger_sql = rolling_trigger_sql(connection)

      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)
      migration.suppress_messages { migration.migrate(:up) }
      expect(rolling_trigger_sql(connection)).to eq(trigger_sql)

      migration.suppress_messages { migration.migrate(:down) }
      expect(rolling_trigger_sql(connection)).to eq(trigger_sql)
    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def build_prior_release_schema(connection)
    connection.create_table(:admin_users)
    connection.create_table(:chat_rooms)
    connection.create_table(:chat_messages) do |table|
      table.references :chat_room, null: false
      table.string :public_id
    end
    connection.add_index(:chat_messages, %i[id chat_room_id], unique: true)
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

  def rolling_trigger_sql(connection)
    connection.select_rows(<<~SQL.squish)
      SELECT name, sql
      FROM sqlite_master
      WHERE type = 'trigger' AND name LIKE 'chat_messages_%'
      ORDER BY name
    SQL
  end
end
