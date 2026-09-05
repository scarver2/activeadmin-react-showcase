# script/backup_sqlite.rb
# frozen_string_literal: true

puts SqliteBackupJob.perform_now
