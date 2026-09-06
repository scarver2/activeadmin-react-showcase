# spec/jobs/sqlite_backup_job_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "climate_control"
require "tmpdir"

RSpec.describe SqliteBackupJob do
  it "backs up the configured SQLite databases" do
    Dir.mktmpdir do |directory|
      ClimateControl.modify(SQLITE_BACKUP_DIR: directory) do
        snapshot = described_class.perform_now

        expect(File).to exist(File.join(snapshot, "primary.sqlite3"))
        expect(File.read(File.join(snapshot, "SHA256SUMS"))).to include("primary.sqlite3")
      end
    end
  end

  it "preserves absolute configured database paths" do
    configuration = instance_double(
      ActiveRecord::DatabaseConfigurations::HashConfig,
      database: "/var/lib/showcase.sqlite3",
      name: "primary"
    )
    allow(ActiveRecord::Base.configurations).to receive(:configs_for).and_return([ configuration ])

    expect(described_class.new.send(:database_paths)).to eq("primary" => "/var/lib/showcase.sqlite3")
  end
end
