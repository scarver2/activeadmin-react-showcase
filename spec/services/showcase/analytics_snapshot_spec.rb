# spec/services/showcase/analytics_snapshot_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::AnalyticsSnapshot do
  subject(:snapshot) { described_class.new(start_date:, end_date:).as_json }

  let(:start_date) { Date.new(2026, 9, 1) }
  let(:end_date) { Date.new(2026, 9, 2) }
  let(:account) { create(:account, plan: "Growth") }

  before do
    create(
      :daily_metric,
      account:,
      active_users: 10,
      error_count: 2,
      p95_ms: 120,
      recorded_on: start_date,
      request_count: 100,
      revenue_cents: 1_000
    )
    create(
      :daily_metric,
      account:,
      active_users: 20,
      error_count: 1,
      p95_ms: 180,
      recorded_on: end_date,
      request_count: 200,
      revenue_cents: 2_000
    )
  end

  it "returns the portable chart contract" do
    expect(snapshot).to include(
      accounts: [ { activeUsers: 30, name: account.name, revenueCents: 3_000 } ],
      kpis: { activeUsers: 30, errorRate: 1.0, p95Ms: 150, revenueCents: 3_000 },
      plans: [ { name: "Growth", value: 1 } ],
      range: { endDate: "2026-09-02", startDate: "2026-09-01" }
    )
    expect(snapshot.fetch(:series)).to contain_exactly(
      { activeUsers: 10, date: "2026-09-01", requestCount: 100, revenueCents: 1_000 },
      { activeUsers: 20, date: "2026-09-02", requestCount: 200, revenueCents: 2_000 }
    )
  end

  it "returns zero KPIs and empty chart series without metrics" do
    empty = described_class.new(start_date: start_date - 2.days, end_date: start_date - 1.day).as_json

    expect(empty.fetch(:kpis)).to eq(activeUsers: 0, errorRate: 0.0, p95Ms: 0, revenueCents: 0)
    expect(empty.fetch(:series)).to be_empty
  end

  it "rejects a reversed range" do
    expect { described_class.new(start_date: end_date, end_date: start_date) }
      .to raise_error(ArgumentError, "start_date must not be after end_date")
  end

  it "rejects more than 90 inclusive days" do
    expect { described_class.new(start_date:, end_date: start_date + 90.days) }
      .to raise_error(ArgumentError, "date range must not exceed 90 days")
  end
end
