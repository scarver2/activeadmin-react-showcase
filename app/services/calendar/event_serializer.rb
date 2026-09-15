# app/services/calendar/event_serializer.rb
# frozen_string_literal: true

module Calendar
  class EventSerializer
    def initialize(event)
      @event = event
    end

    def as_json(*)
      {
        id: event.id.to_s,
        title: event.title,
        start: event.starts_at.iso8601,
        end: event.ends_at.iso8601,
        extendedProps: {
          editUrl: Rails.application.routes.url_helpers.edit_admin_schedule_event_path(event),
          location: event.location,
          lockVersion: event.lock_version,
          notes: event.notes,
          timeZone: event.time_zone,
          updateUrl: Rails.application.routes.url_helpers.admin_calendar_event_path(event)
        }
      }
    end

    private

    attr_reader :event
  end
end
