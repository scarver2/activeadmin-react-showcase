# app/services/calendar/save_event.rb
# frozen_string_literal: true

module Calendar
  class SaveEvent
    class StaleWrite < StandardError; end

    def self.call(admin_user:, attributes:, event: nil, expected_lock_version: nil)
      new(admin_user:, attributes:, event:, expected_lock_version:).call
    end

    def initialize(admin_user:, attributes:, event:, expected_lock_version:)
      @admin_user = admin_user
      @attributes = attributes.to_h.symbolize_keys
      @event = event
      @expected_lock_version = expected_lock_version
    end

    def call
      return create_event unless event

      event.with_lock do
        raise StaleWrite, "This event changed after the calendar loaded" unless current_version?

        event.update!(normalized_attributes)
      end
      event
    end

    private

    attr_reader :admin_user, :attributes, :event, :expected_lock_version

    def create_event
      admin_user.schedule_events.create!(normalized_attributes)
    end

    def current_version?
      Integer(expected_lock_version.to_s, 10, exception: false) == event.lock_version
    end

    def normalized_attributes
      zone_name = attributes.fetch(:time_zone, event&.time_zone)
      attributes.merge(
        ends_at: parse_time(attributes[:ends_at], zone_name),
        starts_at: parse_time(attributes[:starts_at], zone_name)
      )
    end

    def parse_time(value, zone_name)
      return value if value.respond_to?(:acts_like_time?) && value.acts_like_time?

      text = value.to_s
      return Time.iso8601(text) if text.match?(/(?:Z|[+-]\d{2}:\d{2})\z/i)

      ActiveSupport::TimeZone[zone_name]&.parse(text) || raise(ArgumentError, "Unsupported calendar time or zone")
    rescue ArgumentError
      raise ArgumentError, "Unsupported calendar time or zone"
    end
  end
end
