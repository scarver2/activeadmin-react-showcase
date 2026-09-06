# spec/services/showcase/telemetry/cable_tracker_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::Telemetry::CableTracker do
  subject(:tracker) { described_class.new }

  it "tracks actual concurrent subscription and delivery activity safely" do
    threads = 4.times.map do |index|
      Thread.new do
        tracker.connected("session-#{index}")
        tracker.delivered(index.even? ? :live : :replay)
      end
    end
    threads.each(&:join)

    expect(tracker.snapshot).to eq(
      active_subscriptions: 4,
      deliveries_last_five_minutes: 4,
      live_deliveries: 2,
      replay_deliveries: 2
    )
    4.times { |index| tracker.disconnected("session-#{index}") }
    expect(tracker.snapshot[:active_subscriptions]).to eq(0)
  end
end
