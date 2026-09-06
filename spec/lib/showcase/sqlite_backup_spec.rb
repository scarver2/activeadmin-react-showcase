# spec/lib/showcase/sqlite_backup_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "showcase/sqlite_backup"

RSpec.describe Showcase::SqliteBackup do
  it "creates a consistent database copy and checksum manifest" do
    Dir.mktmpdir do |directory|
      source_path = File.join(directory, "source.sqlite3")
      source = SQLite3::Database.new(source_path)
      source.execute("CREATE TABLE examples (name TEXT NOT NULL)")
      source.execute("INSERT INTO examples (name) VALUES (?)", "Bluebonnet Logistics")
      source.close

      snapshot = described_class.call(
        destination: File.join(directory, "backups"),
        sources: { "primary" => source_path },
        timestamp: Time.utc(2026, 9, 5, 12)
      )

      backup_path = File.join(snapshot, "primary.sqlite3")
      backup = SQLite3::Database.new(backup_path)

      expect(backup.get_first_value("SELECT name FROM examples")).to eq("Bluebonnet Logistics")
      expect(File.read(File.join(snapshot, "SHA256SUMS"))).to include(Digest::SHA256.file(backup_path).hexdigest)
    ensure
      backup&.close
    end
  end

  it "rejects a missing source database" do
    Dir.mktmpdir do |directory|
      expect do
        described_class.call(
          destination: File.join(directory, "backups"),
          sources: { "missing" => File.join(directory, "missing.sqlite3") },
          timestamp: Time.utc(2026, 9, 5, 12)
        )
      end.to raise_error(RuntimeError, /database does not exist/)
    end
  end

  it "closes safely when SQLite cannot open a source" do
    Dir.mktmpdir do |directory|
      source_path = File.join(directory, "source.sqlite3")
      FileUtils.touch(source_path)
      allow(SQLite3::Database).to receive(:new).and_raise(SQLite3::CantOpenException)

      expect do
        described_class.call(
          destination: File.join(directory, "backups"),
          sources: { "primary" => source_path },
          timestamp: Time.utc(2026, 9, 5, 12)
        )
      end.to raise_error(SQLite3::CantOpenException)
    end
  end
end
