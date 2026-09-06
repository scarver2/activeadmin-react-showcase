# spec/services/showcase/telemetry/request_store_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::Telemetry::RequestStore do
  subject(:store) { described_class.new }

  before { allow(Rails.cache).to receive(:read).and_return([]) }

  it "keeps a bounded application-local request sample" do
    allow(Rails.cache).to receive(:write)

    store.record(duration_ms: 12.345, status: 200)

    expect(Rails.cache).to have_received(:write).with(described_class::CACHE_KEY, [ { "duration_ms" => 12.3, "status" => 200 } ], expires_in: 1.day)
  end

  it "degrades safely when the Solid Cache database is unavailable" do
    allow(Rails.cache).to receive(:read).and_raise(ActiveRecord::ConnectionNotEstablished)

    expect(store.samples).to eq([])
  end
end
