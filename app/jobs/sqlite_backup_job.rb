# app/jobs/sqlite_backup_job.rb
# frozen_string_literal: true

class SqliteBackupJob < ApplicationJob
  queue_as :maintenance

  def perform
    snapshot = Showcase::SqliteBackup.call(
      destination: ENV.fetch("SQLITE_BACKUP_DIR"),
      sources: database_paths
    )

    Rails.logger.info("Created SQLite backup snapshot at #{snapshot}")
    snapshot
  end

  private

  def database_paths
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).to_h do |configuration|
      path = Pathname.new(configuration.database)
      path = Rails.root.join(path) unless path.absolute?
      [ configuration.name, path.to_s ]
    end
  end
end
