# spec/services/calendar_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calendar services" do
  let(:admin) { create(:admin_user) }

  describe Calendar::EventQuery do
    it "returns only the owner's overlapping events in chronological order" do
      later = create(:schedule_event, admin_user: admin, starts_at: Time.zone.parse("2026-09-16 12:00 UTC"))
      earlier = create(:schedule_event, admin_user: admin, starts_at: Time.zone.parse("2026-09-15 12:00 UTC"))
      create(:schedule_event, starts_at: earlier.starts_at)

      payload = described_class.new(
        admin_user: admin,
        starts_at: "2026-09-15T00:00:00Z",
        ends_at: "2026-09-17T00:00:00Z"
      ).as_json

      expect(payload.dig(:events, 0, :id)).to eq(earlier.id.to_s)
      expect(payload.fetch(:events).pluck(:id)).to eq([ earlier.id.to_s, later.id.to_s ])
      expect(payload.dig(:events, 0, :extendedProps)).to include(:editUrl, :updateUrl, timeZone: "America/Chicago")
    end

    it "rejects malformed, reversed, and excessive ranges" do
      expect { query("bad", "2026-09-17T00:00:00Z") }.to raise_error(ArgumentError, /ISO 8601/)
      expect { query("2026-09-17T00:00:00Z", "2026-09-16T00:00:00Z") }.to raise_error(ArgumentError, /after start/)
      expect { query("2026-01-01T00:00:00Z", "2026-12-31T00:00:00Z") }.to raise_error(ArgumentError, /93 days/)
    end

    def query(starts_at, ends_at)
      described_class.new(admin_user: admin, starts_at:, ends_at:).events.to_a
    end
  end

  describe Calendar::SaveEvent do
    let(:attributes) do
      {
        title: "Zone-aware planning",
        starts_at: "2026-09-15T09:00",
        ends_at: "2026-09-15T10:00",
        time_zone: "America/Chicago"
      }
    end

    it "creates UTC instants from a Rails-owned presentation zone" do
      event = described_class.call(admin_user: admin, attributes:)

      expect(event.starts_at).to eq(Time.iso8601("2026-09-15T14:00:00Z"))
      expect(event.admin_user).to eq(admin)
    end

    it "updates an owned event from offset timestamps and increments its lock" do
      event = create(:schedule_event, admin_user: admin)

      result = described_class.call(
        admin_user: admin,
        attributes: attributes.merge(starts_at: "2026-09-15T11:00:00Z", ends_at: "2026-09-15T12:00:00Z"),
        event:,
        expected_lock_version: event.lock_version
      )

      expect(result.starts_at).to eq(Time.iso8601("2026-09-15T11:00:00Z"))
      expect(result.lock_version).to eq(1)
    end

    it "rejects stale versions and unsupported time input" do
      event = create(:schedule_event, admin_user: admin)

      expect do
        described_class.call(admin_user: admin, attributes:, event:, expected_lock_version: 99)
      end.to raise_error(Calendar::SaveEvent::StaleWrite)

      expect do
        described_class.call(admin_user: admin, attributes: attributes.merge(starts_at: "not-a-time"))
      end.to raise_error(ArgumentError, /Unsupported calendar time or zone/)
    end

    it "accepts already-cast Rails time values" do
      event = described_class.call(
        admin_user: admin,
        attributes: attributes.merge(starts_at: Time.zone.parse("2026-09-15 14:00 UTC"), ends_at: Time.zone.parse("2026-09-15 15:00 UTC"))
      )

      expect(event.starts_at).to eq(Time.iso8601("2026-09-15T14:00:00Z"))
    end
  end

  describe Calendar::Seed do
    it "creates deterministic events idempotently" do
      expect { described_class.call(admin_user: admin) }.to change(admin.schedule_events, :count).by(4)
      expect { described_class.call(admin_user: admin) }.not_to change(admin.schedule_events, :count)
    end
  end
end
