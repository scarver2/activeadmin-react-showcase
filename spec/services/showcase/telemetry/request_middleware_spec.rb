# spec/services/showcase/telemetry/request_middleware_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::Telemetry::RequestMiddleware do
  let(:store) { instance_double(Showcase::Telemetry::RequestStore, record: nil) }

  it "records request status and latency without changing the response" do
    app = ->(_env) { [ 204, {}, [] ] }

    response = described_class.new(app, store:).call({})

    expect(response.first).to eq(204)
    expect(store).to have_received(:record).with(duration_ms: be >= 0, status: 204)
  end

  it "records failed requests and preserves the exception" do
    app = ->(_env) { raise "boom" }

    expect { described_class.new(app, store:).call({}) }.to raise_error("boom")
    expect(store).to have_received(:record).with(duration_ms: be >= 0, status: 500)
  end
end
