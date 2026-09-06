# app/services/showcase/telemetry/request_store.rb
# frozen_string_literal: true

module Showcase
  module Telemetry
    class RequestStore
      CACHE_KEY = "showcase:telemetry:requests:v1"
      LIMIT = 100

      def record(duration_ms:, status:)
        samples = Rails.cache.read(CACHE_KEY) || []
        samples = samples.last(LIMIT - 1) << { "duration_ms" => duration_ms.round(1), "status" => status }
        Rails.cache.write(CACHE_KEY, samples, expires_in: 1.day)
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.warn("Telemetry request sample was not persisted: #{e.class}")
      end

      def samples
        Rails.cache.read(CACHE_KEY) || []
      rescue ActiveRecord::ActiveRecordError
        []
      end
    end
  end
end
