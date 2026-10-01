# spec/services/showcase/bulk_regions_concurrency_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Concurrent bulk workers", database_cleaner: :truncation do
  it "commits only one account mutation per selected record" do
    account = create(:account)
    admin = create(:admin_user)
    batch = Showcase::BulkRegions.preview(admin_user: admin, ids: [ account.id ], region: "East")
    Showcase::BulkRegions.confirm(admin_user: admin, id: batch.id)
    ready = Queue.new
    start = Queue.new
    threads = 4.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          Showcase::BulkRegions.perform(batch.id)
        end
      end
    end
    4.times { ready.pop }
    4.times { start << true }
    threads.map(&:value)
    expect(batch.reload.results).to eq(account.id.to_s => "updated")
    expect(account.reload.lock_version).to eq(1)
  end
end
