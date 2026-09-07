# app/services/showcase/telemetry/snapshot.rb
# frozen_string_literal: true

module Showcase
  module Telemetry
    class Snapshot
      def initialize(request_store: RequestStore.new, cable_tracker: Rails.application.config.x.showcase_cable_tracker, clock: Time)
        @request_store = request_store
        @cable_tracker = cable_tracker
        @clock = clock
      end

      def as_json(*)
        {
          requests: request_metrics,
          database: database_metrics,
          cable: cable_metrics,
          runtime: runtime_metrics,
          health: health_metrics,
          observed_at: clock.current.iso8601(6)
        }
      end

      private

      attr_reader :cable_tracker, :clock, :request_store

      def cable_metrics
        cable_tracker.snapshot
      end

      def database_metrics
        stat = ActiveRecord::Base.connection_pool.stat
        { connections_busy: stat.fetch(:busy), connections_idle: stat.fetch(:idle), connections_total: stat.fetch(:size) }
      end

      def health_metrics
        recent_errors = request_store.samples.count { |sample| sample.fetch("status") >= 500 }
        { status: ActiveRecord::Base.connection.active? ? "healthy" : "degraded", recent_request_errors: recent_errors }
      rescue ActiveRecord::ActiveRecordError
        { status: "degraded", recent_request_errors: nil }
      end

      def request_metrics
        samples = request_store.samples
        durations = samples.map { |sample| sample.fetch("duration_ms") }.sort
        {
          count: samples.length,
          error_count: samples.count { |sample| sample.fetch("status") >= 500 },
          p95_ms: percentile(durations, 0.95)
        }
      end

      def runtime_metrics
        database = ActiveRecord::Base.connection_db_config.database
        {
          cpu_seconds: Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID).round(2),
          ruby_heap_mb: (GC.stat.fetch(:heap_live_slots) * 40.0 / 1_048_576).round(2),
          sqlite_mb: File.exist?(database) ? (File.size(database).to_f / 1_048_576).round(2) : 0
        }
      end

      def percentile(values, percentile)
        return 0 if values.empty?

        values[((values.length - 1) * percentile).ceil]
      end
    end
  end
end
