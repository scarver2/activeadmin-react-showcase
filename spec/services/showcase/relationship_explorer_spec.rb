# spec/services/showcase/relationship_explorer_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::RelationshipExplorer do
  subject(:payload) { described_class.new(**options).as_json }

  let(:options) { {} }
  let!(:bluebonnet) { create(:account, name: "Bluebonnet Logistics", plan: "Enterprise", region: "Central") }
  let!(:cedar) { create(:account, name: "Cedar Ridge Health", plan: "Growth", region: "East", status: "trial") }
  let!(:high_plains) { create(:account, name: "High Plains Supply", plan: "Starter", region: "West") }

  before do
    create(:contact, account: bluebonnet, email: "marisol@bluebonnet.example", first_name: "Marisol", last_name: "Vega", relationship_role: "Executive sponsor")
    create(:contact, account: bluebonnet, email: "priya@bluebonnet.example", first_name: "Priya", job_title: "Integration Engineer", last_name: "Nair", relationship_role: "Technical lead")
    create(:contact, account: cedar, email: "tessa@cedar.example", first_name: "Tessa", last_name: "Nguyen")
  end

  it "returns sorted account summaries and the first account relationship detail" do
    expect(payload).to include(total: 3, truncated: false)
    expect(payload.fetch(:accounts).pluck(:name)).to eq([ "Bluebonnet Logistics", "Cedar Ridge Health", "High Plains Supply" ])
    expect(payload.fetch(:accounts).first).to include(contactCount: 2, plan: "Enterprise", region: "Central")
    expect(payload.fetch(:selectedAccount)).to include(
      href: a_string_matching(%r{/admin/accounts/\d+}),
      name: "Bluebonnet Logistics"
    )
    expect(payload.dig(:selectedAccount, :contacts).pluck(:fullName)).to eq([ "Priya Nair", "Marisol Vega" ])
    expect(payload.dig(:selectedAccount, :contacts).first.fetch(:href)).to match(%r{/admin/contacts/\d+})
  end

  it "searches approved account and contact fields case-insensitively" do
    result = described_class.new(query: "INTEGRATION").as_json

    expect(result.fetch(:accounts).pluck(:name)).to eq([ "Bluebonnet Logistics" ])
  end

  it "combines allowlisted account and relationship filters" do
    result = described_class.new(
      plan: "Enterprise",
      region: "Central",
      relationship_role: "Technical lead"
    ).as_json

    expect(result.fetch(:accounts).pluck(:name)).to eq([ "Bluebonnet Logistics" ])
  end

  it "selects an available account and rejects one outside the filtered result" do
    selected = described_class.new(selected_id: cedar.id).as_json

    expect(selected.dig(:selectedAccount, :name)).to eq("Cedar Ridge Health")
    expect { described_class.new(plan: "Starter", selected_id: cedar.id).as_json }
      .to raise_error(ArgumentError, "selected_id is not available in these filters")
  end

  it "returns an empty relationship state" do
    empty = described_class.new(query: "missing").as_json

    expect(empty).to include(accounts: [], selectedAccount: nil, total: 0, truncated: false)
  end

  it "caps the account population" do
    20.times { |number| create(:account, name: "Overflow Account #{number}") }

    expect(payload).to include(total: 23, truncated: true)
    expect(payload.fetch(:accounts).length).to eq(20)
  end

  it "rejects malformed or unsupported controls" do
    invalid = [
      [ { plan: "Unlimited" }, "plan is not supported" ],
      [ { query: [ "Blue" ] }, "query must be text" ],
      [ { query: "x" * 81 }, "query must not exceed 80 characters" ],
      [ { region: "North" }, "region is not supported" ],
      [ { relationship_role: "Prospect" }, "relationship_role is not supported" ],
      [ { selected_id: "many" }, "selected_id must be an integer" ],
      [ { selected_id: 0 }, "selected_id must be positive" ]
    ]

    invalid.each do |arguments, message|
      expect { described_class.new(**arguments) }.to raise_error(ArgumentError, message)
    end
  end
end
