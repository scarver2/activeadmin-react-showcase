# spec/requests/admin/calendar_events_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin calendar events" do
  let(:admin) { create(:admin_user) }
  let(:headers) { { "ACCEPT" => "application/json" } }
  let(:valid_event) do
    {
      title: "Release review",
      starts_at: "2026-09-15T09:00",
      ends_at: "2026-09-15T10:00",
      time_zone: "America/Chicago"
    }
  end

  it "requires authentication for reads and writes" do
    get admin_calendar_events_path, params: bounds, headers: headers
    expect(response).to have_http_status(:unauthorized)

    post admin_calendar_events_path, params: { event: valid_event }, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns bounded owner-scoped events and rejects malformed ranges" do
    sign_in admin
    owned = create(:schedule_event, admin_user: admin)
    create(:schedule_event, starts_at: owned.starts_at)

    get admin_calendar_events_path, params: bounds, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("events").pluck("id")).to eq([ owned.id.to_s ])

    get admin_calendar_events_path, params: { start: "bad", end: bounds[:end] }, headers: headers
    expect(response).to have_http_status(:bad_request)
  end

  it "creates a valid event and reports validation errors" do
    sign_in admin

    expect do
      post admin_calendar_events_path, params: { event: valid_event }, headers: headers
    end.to change(admin.schedule_events, :count).by(1)
    expect(response).to have_http_status(:created)

    post admin_calendar_events_path, params: { event: valid_event.merge(title: "") }, headers: headers
    expect(response).to have_http_status(:unprocessable_content)

    post admin_calendar_events_path, params: { event: valid_event.merge(starts_at: "bad") }, headers: headers
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "updates canonically, rejects overlap and stale writes, and scopes ownership" do
    sign_in admin
    event = create(:schedule_event, admin_user: admin)
    blocker = create(:schedule_event, admin_user: admin, starts_at: event.ends_at + 1.hour)

    patch admin_calendar_event_path(event), params: {
      event: { starts_at: "2026-09-14T15:00:00Z", ends_at: "2026-09-14T16:00:00Z", time_zone: "UTC" },
      lock_version: event.lock_version
    }, headers: headers
    expect(response).to have_http_status(:ok)

    patch admin_calendar_event_path(event), params: {
      event: { starts_at: blocker.starts_at.iso8601, ends_at: blocker.ends_at.iso8601, time_zone: "UTC" },
      lock_version: event.reload.lock_version
    }, headers: headers
    expect(response).to have_http_status(:unprocessable_content)

    patch admin_calendar_event_path(event), params: { event: valid_event, lock_version: 99 }, headers: headers
    expect(response).to have_http_status(:conflict)

    outsider = create(:schedule_event)
    patch admin_calendar_event_path(outsider), params: { event: valid_event, lock_version: 0 }, headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it "renders the page and ordinary ActiveAdmin fallback without creating records" do
    sign_in admin
    event = create(:schedule_event, admin_user: admin)

    expect { get admin_calendar_scheduler_path }.not_to change(ScheduleEvent, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("CalendarScheduler", event.title, "Create a scheduled event", "Edit")
  end

  def bounds
    { start: "2026-09-01T00:00:00Z", end: "2026-10-01T00:00:00Z" }
  end
end
