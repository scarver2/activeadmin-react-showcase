# spec/services/showcase/telemetry/request_store_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::Telemetry::RequestStore, database_cleaner: :truncation do
  subject(:store) { described_class.new }

  it "persists an application-local request sample" do
    store.record(duration_ms: 12.345, status: 200)

    expect(store.samples).to eq([ { "duration_ms" => 12.3, "status" => 200 } ])
  end

  it "records concurrent samples safely through SQLite transactions" do
    errors = Queue.new
    threads = 4.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          store.record(duration_ms: index + 1, status: 200)
        end
      rescue StandardError => e
        errors << e
      end
    end
    threads.each(&:join)

    expect(errors).to be_empty
    expect(TelemetryRequestSample.count).to eq(4)
  end

  it "degrades safely when the primary database is unavailable" do
    allow(TelemetryRequestSample).to receive(:order).and_raise(ActiveRecord::ConnectionNotEstablished)

    expect(store.samples).to eq([])
  end
end
