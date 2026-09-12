# spec/models/schedule_event_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduleEvent do
  subject(:event) { build(:schedule_event) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_presence_of(:ends_at) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:time_zone) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_inclusion_of(:time_zone).in_array(described_class::TIME_ZONES) }

  it "rejects nonpositive and excessive durations" do
    event.ends_at = event.starts_at
    expect(event).not_to be_valid
    expect(event.errors[:ends_at]).to include("must be after the start")

    event.ends_at = event.starts_at + 13.hours
    expect(event).not_to be_valid
    expect(event.errors[:ends_at]).to include("must be within 12 hours of the start")
  end

  it "rejects overlap for one owner but permits the same instant for another" do
    existing = create(:schedule_event)
    overlapping = build(:schedule_event, admin_user: existing.admin_user, starts_at: existing.starts_at + 30.minutes)
    other_owner = build(:schedule_event, starts_at: existing.starts_at + 30.minutes)

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:base]).to include("overlaps #{existing.title}")
    expect(other_owner).to be_valid
  end

  it "presents a stored UTC instant in its allowlisted zone" do
    expect(event.localized_start.formatted_offset).to eq("-05:00")
  end

  it "exposes only explicit ActiveAdmin search fields" do
    expect(described_class.ransackable_associations).to eq([])
    expect(described_class.ransackable_attributes).to include("starts_at", "time_zone", "title")
  end
end
