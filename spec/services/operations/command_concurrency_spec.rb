# spec/services/operations/command_concurrency_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Concurrent operation commands", database_cleaner: :truncation do
  def concurrently(count, &block)
    ready = Queue.new
    start = Queue.new
    threads = count.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          block.call
        end
      end
    end
    count.times { ready.pop }
    count.times { start << true }
    threads.map(&:value)
  end

  before do
    allow(ActionCable.server).to receive(:broadcast)
    allow(DemoOperationJob).to receive(:perform_later)
  end

  it "reconciles the unique-key winner for simultaneous create commands" do
    admin_user = create(:admin_user)

    operation_ids = concurrently(4) do
      Operations::Create.call(
        admin_user: AdminUser.find(admin_user.id),
        kind: "successful_demo",
        request_idempotency_key: "one-command"
      ).id
    end

    expect(operation_ids.uniq.one?).to be(true)
    expect(Operation.where(request_idempotency_key: "one-command").count).to eq(1)
    expect(DemoOperationJob).to have_received(:perform_later).once
  end

  it "serializes simultaneous cancellation commands into one durable event" do
    operation = create(:operation)

    concurrently(4) do
      Operations::Cancel.call(operation: Operation.find(operation.id), idempotency_key: "cancel:#{operation.public_id}")
    end

    expect(operation.reload).to have_attributes(state: "cancelled", cancel_idempotency_key: "cancel:#{operation.public_id}")
    expect(operation.events.where(state: "cancelled").count).to eq(1)
  end
end
