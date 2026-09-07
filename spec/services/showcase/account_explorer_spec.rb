# spec/services/showcase/account_explorer_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::AccountExplorer do
  subject(:payload) { described_class.new(**options).as_json }

  let(:options) { {} }

  before do
    create(:daily_metric, account: create(:account, name: "Bluebonnet", plan: "Enterprise"), active_users: 30, revenue_cents: 2_500)
    create(:daily_metric, account: create(:account, name: "Cedar", plan: "Growth", status: "trial"), active_users: 20, revenue_cents: 1_500)
    create(:account, name: "Alamo", plan: "Starter")
  end

  it "returns a bounded page with aggregate display data and filter options" do
    expect(payload).to include(
      filters: { plans: Account::PLANS, statuses: Account::STATUSES },
      page: 1,
      perPage: 5,
      total: 3,
      totalPages: 1
    )
    expect(payload.fetch(:rows).pluck(:name)).to eq(%w[Alamo Bluebonnet Cedar])
    expect(payload.fetch(:rows).second).to include(activeUsers: 30, revenueCents: 2_500, href: a_string_matching(%r{/admin/accounts/\d+}))
  end

  it "filters, sorts, and paginates only through allowlisted fields" do
    explorer = described_class.new(direction: "desc", page: "1", per_page: "5", plan: "Growth", query: "ed", sort: "name", status: "trial")

    expect(explorer.as_json.fetch(:rows).pluck(:name)).to eq([ "Cedar" ])
    expect(explorer.as_json.fetch(:sort)).to eq(direction: "desc", field: "name")
  end

  it "returns an empty bounded page" do
    empty = described_class.new(query: "missing").as_json

    expect(empty).to include(rows: [], total: 0, totalPages: 1)
  end

  it "rejects unsupported and malformed query controls" do
    invalid = [
      [ { direction: "sideways" }, "direction is not supported" ],
      [ { page: "zero" }, "value must be an integer" ],
      [ { page: 101 }, "page must be between 1 and 100" ],
      [ { per_page: "many" }, "per_page must be an integer" ],
      [ { per_page: 7 }, "per_page is not supported" ],
      [ { plan: "Unlimited" }, "plan is not supported" ],
      [ { query: [ "Blue" ] }, "query must be text" ],
      [ { query: "x" * 81 }, "query must not exceed 80 characters" ],
      [ { sort: "revenue" }, "sort is not supported" ],
      [ { status: "deleted" }, "status is not supported" ]
    ]

    invalid.each do |arguments, message|
      expect { described_class.new(**arguments) }.to raise_error(ArgumentError, message)
    end
  end
end
