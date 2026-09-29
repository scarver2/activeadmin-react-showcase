# spec/services/showcase/account_inspector_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::AccountInspector do
  def routes
    Rails.application.routes.url_helpers
  end

  let(:account) { create(:account, name: "Bluebonnet Logistics", plan: "Enterprise", region: "West", status: "trial") }

  before do
    create(:contact, account:)
    create(:daily_metric, account:, active_users: 41, recorded_on: Date.new(2026, 9, 27), revenue_cents: 240_000)
    create(:daily_metric, account:, active_users: 52, recorded_on: Date.new(2026, 9, 28), revenue_cents: 315_000)
  end

  it "returns a bounded Rails-owned account, metric, relationship, and action contract" do
    payload = described_class.new(account:, can_edit: true).as_json

    expect(payload).to include(
      account: { id: account.id, name: "Bluebonnet Logistics", plan: "Enterprise", region: "West", status: "trial" },
      canonicalHref: routes.admin_account_path(account),
      metrics: { activeUsers: 52, recordedOn: "2026-09-28", revenueCents: 315_000 },
      relationships: { contacts: 1, observations: 2 }
    )
    expect(payload.fetch(:actions)).to eq([
      { href: routes.admin_account_path(account), label: "View full account" },
      { href: routes.edit_admin_account_path(account), label: "Edit account" }
    ])
  end

  it "omits actions the current authorization adapter denies" do
    payload = described_class.new(account:, can_edit: false).as_json

    expect(payload.fetch(:actions)).to eq([
      { href: routes.admin_account_path(account), label: "View full account" }
    ])
  end
end
