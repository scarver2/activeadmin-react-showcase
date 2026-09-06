# spec/services/showcase/telemetry/snapshot_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::Telemetry::Snapshot do
  let(:request_store) do
    instance_double(
      Showcase::Telemetry::RequestStore,
      samples: [
        { "duration_ms" => 12.0, "status" => 200 },
        { "duration_ms" => 48.0, "status" => 500 }
      ]
    )
  end

  it "collects provider-neutral application, database, Cable, runtime, disk, and health metrics" do
    snapshot = described_class.new(request_store:).as_json

    expect(snapshot[:requests]).to eq(count: 2, error_count: 1, p95_ms: 48.0)
    expect(snapshot[:database]).to include(:connections_busy, :connections_idle, :connections_total)
    expect(snapshot[:cable]).to include(:events_last_five_minutes, :active_operations)
    expect(snapshot[:runtime]).to include(:cpu_seconds, :ruby_heap_mb, :sqlite_mb)
    expect(snapshot[:health]).to eq(status: "healthy", recent_request_errors: 1)
  end

  it "reports zero request latency when no samples exist" do
    allow(request_store).to receive(:samples).and_return([])

    expect(described_class.new(request_store:).as_json[:requests]).to eq(count: 0, error_count: 0, p95_ms: 0)
  end

  it "reports degraded health when the primary database check fails" do
    allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(ActiveRecord::ConnectionNotEstablished)

    expect(described_class.new(request_store:).as_json[:health]).to eq(status: "degraded", recent_request_errors: nil)
  end
end
