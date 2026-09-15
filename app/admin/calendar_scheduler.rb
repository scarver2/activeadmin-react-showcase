# app/admin/calendar_scheduler.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Calendar Scheduler" do
  menu label: "Calendar Scheduler", parent: "Data & Workflows", priority: 3

  content title: "Rails-authoritative Calendar Scheduler" do
    range_start = Time.current.utc.beginning_of_month.beginning_of_week
    range_end = range_start + Calendar::EventQuery::MAXIMUM_RANGE.to_i
    events = Calendar::EventQuery.new(
      admin_user: current_admin_user,
      starts_at: range_start.iso8601,
      ends_at: range_end.iso8601
    ).events

    panel "Demo" do
      para "Switch month, week, and day views; select time to create an event; or drag an event. Rails owns authorization, overlap decisions, zones, persistence, and stale-write detection."
    end

    react_component(
      "CalendarScheduler",
      props: {
        endpoint: Rails.application.routes.url_helpers.admin_calendar_events_path,
        initialEvents: events.map { |event| Calendar::EventSerializer.new(event).as_json },
        timeZones: ScheduleEvent::TIME_ZONES
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "The authenticated Rails schedule remains available without JavaScript."),
          content_tag(:p, link_to("Create a scheduled event", new_admin_schedule_event_path)),
          content_tag(:ol) do
            safe_join(events.map do |event|
              content_tag(:li) do
                safe_join([
                  content_tag(:strong, event.title),
                  content_tag(:span, " — #{event.localized_start.to_fs(:long)} (#{event.time_zone})"),
                  content_tag(:span, " — "),
                  link_to("Edit", edit_admin_schedule_event_path(event))
                ])
              end
            end)
          end
        ])
      },
      class: "mt-6"
    )

    panel "Ruby", id: "ruby-guidance" do
      para "Calendar::EventQuery bounds authenticated schedule reads to 93 days. Calendar::SaveEvent applies validations, overlap policy, and optimistic locking before serialization."
    end

    panel "JavaScript", id: "javascript-guidance" do
      para "FullCalendar owns calendar presentation, selection, and drag interaction. React proposes changes and reverts immediately when Rails rejects them."
    end

    panel "Architecture", id: "architecture-guidance" do
      para "ScheduleEvent stores UTC instants and an allowlisted presentation zone. SQLite remains authoritative; no browser event is canonical until Rails accepts it."
      para link_to("Read the calendar scheduler guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/calendar-scheduler.md")
    end
  end
end
