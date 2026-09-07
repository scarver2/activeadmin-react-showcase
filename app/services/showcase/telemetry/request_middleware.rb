# app/services/showcase/telemetry/request_middleware.rb
# frozen_string_literal: true

module Showcase
  module Telemetry
    class RequestMiddleware
      def initialize(app, store: RequestStore.new)
        @app = app
        @store = store
      end

      def call(env)
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        status, headers, body = app.call(env)
        record(started_at, status)
        [ status, headers, body ]
      rescue StandardError
        record(started_at, 500)
        raise
      end

      private

      attr_reader :app, :store

      def record(started_at, status)
        duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000
        store.record(duration_ms:, status:)
      end
    end
  end
end
