# spec/migrations/create_bulk_region_batches_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20261001040000_create_bulk_region_batches")

RSpec.describe CreateBulkRegionBatches do
  it "adds and removes the batch store without touching existing account data" do
    Dir.mktmpdir do |directory|
      record = Class.new(ActiveRecord::Base) { self.abstract_class = true }
      record.define_singleton_method(:name) { "BulkMigrationRecord" }
      record.establish_connection(adapter: "sqlite3", database: File.join(directory, "migration.sqlite3"))
      connection = record.connection
      connection.create_table(:admin_users)
      connection.create_table(:accounts) { |table| table.string :name }
      migration = described_class.new
      allow(migration).to receive(:connection).and_return(connection)
      migration.suppress_messages { migration.migrate(:up) }
      expect(connection.table_exists?(:bulk_region_batches)).to be(true)
      expect(connection.columns(:bulk_region_batches).map(&:name)).to include("selection", "results", "admin_user_id")
      migration.suppress_messages { migration.migrate(:down) }
      expect(connection.table_exists?(:bulk_region_batches)).to be(false)
      expect(connection.columns(:accounts).map(&:name)).to eq(%w[id name])
    ensure
      record&.connection_pool&.disconnect!
    end
  end
end
