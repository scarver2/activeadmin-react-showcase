# lib/showcase/sqlite_backup.rb
# frozen_string_literal: true

require "digest"
require "fileutils"
require "sqlite3"

module Showcase
  class SqliteBackup
    def self.call(sources:, destination:, timestamp: Time.now.utc)
      new(sources:, destination:, timestamp:).call
    end

    def initialize(sources:, destination:, timestamp:)
      @destination = File.expand_path(destination)
      @sources = sources.transform_values { |path| File.expand_path(path) }
      @timestamp = timestamp
    end

    def call
      snapshot_directory = File.join(destination, timestamp.strftime("%Y%m%dT%H%M%SZ"))
      FileUtils.mkdir_p(snapshot_directory)

      checksums = sources.sort.to_h do |name, source_path|
        raise "SQLite database does not exist: #{source_path}" unless File.file?(source_path)

        backup_path = File.join(snapshot_directory, "#{name}.sqlite3")
        copy_database(source_path, backup_path)
        [ File.basename(backup_path), Digest::SHA256.file(backup_path).hexdigest ]
      end

      File.write(
        File.join(snapshot_directory, "SHA256SUMS"),
        checksums.map { |file, checksum| "#{checksum}  #{file}" }.join("\n") + "\n"
      )

      snapshot_directory
    end

    private

    attr_reader :destination, :sources, :timestamp

    def copy_database(source_path, backup_path)
      source = SQLite3::Database.new(source_path, readonly: true)
      target = SQLite3::Database.new(backup_path)
      backup = SQLite3::Backup.new(target, "main", source, "main")
      backup.step(-1)
      backup.finish
    ensure
      target&.close
      source&.close
    end
  end
end
