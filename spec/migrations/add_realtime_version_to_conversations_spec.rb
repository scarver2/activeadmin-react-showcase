# spec/migrations/add_realtime_version_to_conversations_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20260929120000_add_realtime_version_to_conversations")

RSpec.describe AddRealtimeVersionToConversations do
  it "applies and rolls back realtime, Noticed adoption, and attention state after the accepted 0.19 schema" do
    with_rolling_database do |database_class, connection|
      build_prior_release_schema(connection)
      before = rolling_triggers(connection)
      connection_pool = database_class.connection_pool
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:migration_connection).and_return(connection)
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:migration_connection_pool).and_return(connection_pool)
      schema_migration = ActiveRecord::SchemaMigration.new(connection_pool)
      schema_migration.create_table
      migration_context = ActiveRecord::MigrationContext.new(
        Rails.root.join("db/migrate").to_s,
        schema_migration,
        ActiveRecord::InternalMetadata.new(connection_pool)
      )
      migration_context.migrations
        .select { |migration| migration.version <= 20_260_929_110_000 }
        .each { |migration| schema_migration.create_version(migration.version.to_s) }

      expect(migration_context.current_version).to eq(20_260_929_110_000)

      migration_context.run(:up, 20_260_929_120_000)
      migration_context.run(:up, 20_260_929_130_000)
      migration_context.run(:up, 20_260_930_140_000)

      expect(migration_context.current_version).to eq(20_260_930_140_000)
      expect(migration_context.pending_migration_versions).to contain_exactly(
        20_260_929_210_000,
        20_260_929_210_001,
        20_261_001_033_000
      )
      expect(connection.columns(:chat_rooms).map(&:name)).to include("realtime_version")
      expect(connection.table_exists?(:noticed_notifications)).to be(true)
      expect(connection.table_exists?(:activity_notifications)).to be(false)
      expect(connection.columns(:noticed_notifications).map(&:name)).to include(
        "attention_kind", "dismissed_at", "lock_version", "priority", "snoozed_until"
      )
      expect(connection.select_value("SELECT recipient_id FROM noticed_notifications")).to eq(7)
      expect(connection.select_one("SELECT * FROM noticed_notifications")).to include(
        "attention_kind" => "fyi",
        "lock_version" => 0,
        "priority" => "normal"
      )
      event_params = JSON.parse(connection.select_value("SELECT params FROM noticed_events"))
      expect(event_params).to include(
        "deep_link" => "/admin/accounts",
        "subject" => "Legacy activity"
      )
      expect(rolling_triggers(connection)).to eq(before)

      connection.create_table(:accounts) { |table| table.string :name }
      migration_context.run(:up, 20_261_001_033_000)
      expect(connection.table_exists?(:reversible_changes)).to be(true)
      expect(connection.table_exists?(:reversible_change_events)).to be(true)
      migration_context.rollback(1)
      expect(connection.table_exists?(:reversible_changes)).to be(false)
      expect(connection.table_exists?(:reversible_change_events)).to be(false)

      migration_context.rollback(1)

      expect(migration_context.current_version).to eq(20_260_929_130_000)
      expect(connection.columns(:noticed_notifications).map(&:name)).not_to include(
        "attention_kind", "dismissed_at", "lock_version", "priority", "snoozed_until"
      )
      expect(connection.table_exists?(:activity_notifications)).to be(false)

      migration_context.rollback(1)

      expect(migration_context.current_version).to eq(20_260_929_120_000)
      expect(connection.table_exists?(:noticed_notifications)).to be(false)
      expect(connection.table_exists?(:activity_notifications)).to be(true)
      expect(connection.columns(:chat_rooms).map(&:name)).to include("realtime_version")
      expect(connection.select_one("SELECT * FROM activity_notifications")).to include(
        "admin_user_id" => 7,
        "deep_link" => "/admin/accounts",
        "subject" => "Legacy activity"
      )

      migration_context.rollback(1)

      expect(migration_context.current_version).to eq(20_260_929_110_000)
      expect(connection.columns(:chat_rooms).map(&:name)).not_to include("realtime_version")
      expect(rolling_triggers(connection)).to eq(before)
    end
  end

  it "preserves exact prior-release SQLite trigger SQL across up and down" do
    with_rolling_database do |_database_class, connection|
      build_prior_release_schema(connection)
      before = rolling_triggers(connection)

      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)
      migration.suppress_messages { migration.up }

      expect(rolling_triggers(connection)).to eq(before)
      expect(connection.columns(:chat_rooms).map(&:name)).to include("realtime_version")
      expect(connection.check_constraints(:chat_rooms).map(&:name)).to include("chat_rooms_realtime_version_nonnegative")
      prove_trigger_behavior(connection, id: 3, timestamp: "2026-09-29 00:00:00")

      migration.suppress_messages { migration.down }

      expect(rolling_triggers(connection)).to eq(before)
      expect(connection.columns(:chat_rooms).map(&:name)).not_to include("realtime_version")
      prove_trigger_behavior(connection, id: 4, sequence: 2, timestamp: "2026-09-29 00:01:00")
    end
  end

  def with_rolling_database
    Dir.mktmpdir do |directory|
      database_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      database_class.define_singleton_method(:name) { "RealtimeMigrationRecord" }
      database_class.establish_connection(adapter: "sqlite3", database: File.join(directory, "rolling.sqlite3"))
      yield database_class, database_class.connection
    ensure
      database_class&.connection_pool&.disconnect!
    end
  end

  def build_prior_release_schema(connection)
    connection.create_table(:admin_users) { |table| table.string :email }
    connection.execute("INSERT INTO admin_users (id, email) VALUES (7, 'legacy@example.test')")
    connection.create_table(:activity_notifications) do |table|
      table.integer :admin_user_id, null: false
      table.string :body, null: false
      table.string :deep_link, null: false
      table.string :kind, null: false
      table.datetime :occurred_at, null: false
      table.datetime :read_at
      table.integer :sequence, null: false
      table.string :subject, null: false
      table.timestamps
    end
    connection.execute(<<~SQL.squish)
      INSERT INTO activity_notifications
        (admin_user_id, body, deep_link, kind, occurred_at, read_at, sequence, subject, created_at, updated_at)
      VALUES
        (7, 'Legacy body', '/admin/accounts', 'account', '2026-09-29 09:00:00', NULL, 1,
         'Legacy activity', '2026-09-29 09:00:00', '2026-09-29 09:00:00')
    SQL
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

  def prove_trigger_behavior(connection, id:, timestamp:, sequence: 1)
    quoted_timestamp = connection.quote(timestamp)
    connection.execute("INSERT OR IGNORE INTO chat_rooms (id) VALUES (1)")
    connection.execute("INSERT OR IGNORE INTO chat_participants (id, chat_room_id) VALUES (2, 1)")
    connection.execute <<~SQL.squish
      INSERT INTO chat_messages (id, author_id, body, chat_room_id, sequence, created_at, updated_at)
      VALUES (#{id}, 2, 'Prior release write', 1, #{sequence}, #{quoted_timestamp}, #{quoted_timestamp})
    SQL
    expect(connection.select_value("SELECT public_id FROM chat_messages WHERE id = #{id}")).to eq("message-#{id}")
    expect(connection.select_value("SELECT last_activity_at FROM chat_rooms WHERE id = 1")).to eq(timestamp)
  end

  def rolling_triggers(connection)
    connection.select_rows(<<~SQL.squish)
      SELECT name, sql
      FROM sqlite_master
      WHERE type = 'trigger' AND name LIKE 'chat_messages_%'
      ORDER BY name
    SQL
  end
end
