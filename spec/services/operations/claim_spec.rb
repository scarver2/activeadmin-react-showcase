# spec/services/operations/claim_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::Claim, database_cleaner: :truncation do
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

  it "fences simultaneous executions of the same serialized job with unique attempt tokens" do
    operation = create(:operation)

    outcomes = concurrently(2) do
      described_class.call(operation: Operation.find(operation.id))
    rescue described_class::Busy
      :busy
    end

    lease = outcomes.grep(described_class::Lease).sole
    expect(outcomes).to contain_exactly(lease, :busy)
    expect(operation.reload).to have_attributes(claim_generation: 1, claim_key: lease.token)
  end

  it "permanently fences an expired owner after takeover" do
    operation = create(:operation)
    started_at = Time.current
    original = described_class.call(operation:, token: "original", now: started_at)
    replacement = described_class.call(operation:, token: "replacement", now: started_at + described_class::LEASE + 1.second)

    expect(replacement.generation).to eq(original.generation + 1)
    expect do
      Operations::Transition.call(operation:, lease: original, state: "running", progress: 20, message: "Stale write")
    end.to raise_error(described_class::Stale)

    Operations::Transition.call(operation:, lease: replacement, state: "running", progress: 20, message: "Current write")
    expect(operation.reload).to have_attributes(claim_key: "replacement", progress: 20)
  end

  it "refuses to renew an expired lease that has not yet been replaced" do
    operation = create(:operation)
    started_at = Time.current
    lease = described_class.call(operation:, now: started_at)

    expect do
      described_class.renew!(operation:, lease:, now: started_at + described_class::LEASE + 1.second)
    end.to raise_error(described_class::Expired)
  end
end
