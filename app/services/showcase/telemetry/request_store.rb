# app/services/showcase/telemetry/request_store.rb
# frozen_string_literal: true

module Showcase
  module Telemetry
    class RequestStore
      LIMIT = 100

      def record(duration_ms:, status:)
        TelemetryRequestSample.create!(duration_ms: duration_ms.round(1), occurred_at: Time.current, status:)
        stale_ids = TelemetryRequestSample.order(occurred_at: :desc, id: :desc).offset(LIMIT).pluck(:id)
        TelemetryRequestSample.where(id: stale_ids).delete_all if stale_ids.any?
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.warn("Telemetry request sample was not persisted: #{e.class}")
      end

      def samples
        TelemetryRequestSample.order(occurred_at: :desc, id: :desc).limit(LIMIT).pluck(:duration_ms, :status).map do |duration_ms, status|
          { "duration_ms" => duration_ms, "status" => status }
        end
      rescue ActiveRecord::ActiveRecordError
        []
      end
    end
  end
end
