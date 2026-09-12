# app/services/calendar/event_query.rb
# frozen_string_literal: true

module Calendar
  class EventQuery
    MAXIMUM_RANGE = 93.days

    def initialize(admin_user:, starts_at:, ends_at:)
      @admin_user = admin_user
      @ends_at = parse_time(ends_at)
      @starts_at = parse_time(starts_at)
    end

    def events
      validate_range!
      admin_user.schedule_events.overlapping(starts_at, ends_at).chronological
    end

    def as_json
      { events: events.map { |event| EventSerializer.new(event).as_json } }
    end

    private

    attr_reader :admin_user, :ends_at, :starts_at

    def parse_time(value)
      Time.iso8601(value.to_s)
    rescue ArgumentError
      raise ArgumentError, "Calendar bounds must be ISO 8601 timestamps"
    end

    def validate_range!
      raise ArgumentError, "Calendar end must be after start" unless ends_at > starts_at
      raise ArgumentError, "Calendar range cannot exceed 93 days" if ends_at - starts_at > MAXIMUM_RANGE
    end
  end
end
