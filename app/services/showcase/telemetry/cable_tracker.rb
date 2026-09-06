# app/services/showcase/telemetry/cable_tracker.rb
# frozen_string_literal: true

require "set"

module Showcase
  module Telemetry
    class CableTracker
      WINDOW = 5.minutes

      def initialize(clock: Time)
        @clock = clock
        @deliveries = []
        @mutex = Mutex.new
        @sessions = Set.new
      end

      def connected(session_id)
        mutex.synchronize { sessions.add(session_id) }
      end

      def delivered(kind)
        mutex.synchronize do
          prune
          deliveries << { kind:, occurred_at: clock.current }
        end
      end

      def disconnected(session_id)
        mutex.synchronize { sessions.delete(session_id) }
      end

      def snapshot
        mutex.synchronize do
          prune
          {
            active_subscriptions: sessions.length,
            deliveries_last_five_minutes: deliveries.length,
            live_deliveries: deliveries.count { |delivery| delivery[:kind] == :live },
            replay_deliveries: deliveries.count { |delivery| delivery[:kind] == :replay }
          }
        end
      end

      private

      attr_reader :clock, :deliveries, :mutex, :sessions

      def prune
        cutoff = clock.current - WINDOW
        deliveries.reject! { |delivery| delivery[:occurred_at] < cutoff }
      end
    end
  end
end
