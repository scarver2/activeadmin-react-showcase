# spec/services/showcase/reversible_regions_concurrency_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Concurrent reversible commands", database_cleaner: :truncation do
  def concurrently(&block)
    ready = Queue.new
    start = Queue.new
    threads = 4.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          block.call
        end
      end
    end
    4.times { ready.pop }
    4.times { start << true }
    threads.map(&:value)
  end

  it "records one change and one undo for concurrent duplicate submissions" do
    admin = create(:admin_user)
    account = create(:account, status: "active", region: "Central")
    key = SecureRandom.uuid
    receipts = concurrently do
      Showcase::ReversibleRegions.change(admin_user: AdminUser.find(admin.id), account: Account.find(account.id),
        value: "East", request_key: key, expected_version: 0).id
    end
    expect(receipts.uniq.size).to eq(1)
    concurrently do
      Showcase::ReversibleRegions.undo(admin_user: AdminUser.find(admin.id), id: receipts.first)
    end
    expect(account.reload.region).to eq("Central")
    expect(ReversibleChangeEvent.order(:id).pluck(:kind)).to eq(%w[change undo])
  end
end
