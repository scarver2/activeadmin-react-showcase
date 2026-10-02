# spec/services/showcase/activity_timeline_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::ActivityTimeline do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:admin_user) }

  def page(params = {}, sources: Showcase::TimelineSources.new, **filters)
    described_class.new(admin_user: admin, params: params.merge(filters), sources:).page
  end

  def next_params(result)
    Rack::Utils.parse_query(URI.parse(result.fetch(:nextUrl)).query)
  end

  it "projects all seven families with stable event identity and canonical source links" do
    result = page
    expect(result.fetch(:items).size).to eq(25)
    expect(result.fetch(:items).map { |event| event.fetch(:family) }.uniq.sort).to eq(Showcase::TimelineSources::FAMILIES.keys.sort)
    event = result.fetch(:items).first
    expect(event).to include(id: "system-0000", sourceUrl: "/admin/activity_timeline?source=system-0000", state: "available")
    expect(event.fetch(:details)).to include("Origin" => "Demo importer")
    expect(page.fetch(:items)).to eq(result.fetch(:items))
  end

  it "resumes large histories without duplicate or omitted identities, even at tied timestamps" do
    ids = []
    result = page
    loop do
      ids.concat(result.fetch(:items).map { |event| event.fetch(:id) })
      break unless result.fetch(:nextUrl)

      result = page(next_params(result))
    end
    expect(ids.size).to eq(1393)
    expect(ids.uniq).to eq(ids)
    expect(ids.first).to eq("system-0000")
    expect(ids.last).to eq("approval-0199")
  end

  it "deduplicates repeated source envelopes rather than inventing new event identity" do
    sources = Showcase::TimelineSources.new
    records = sources.visible_records(admin_user: admin)
    allow(sources).to receive(:visible_records).with(admin_user: admin).and_return(records + records)
    expect(page({}, sources:).fetch(:items)).to eq(page.fetch(:items))
  end

  it "filters by family, actor and inclusive UTC date before paging" do
    result = page(family: "comment", actor: "Avery Morgan", since: "2026-10-01", group: "family")
    expect(result.fetch(:items)).not_to be_empty
    expect(result.fetch(:items)).to all(include(family: "comment", actor: "Avery Morgan"))
    expect(result.fetch(:items).map { |event| event.fetch(:occurredAt).first(10) }.uniq).to eq([ "2026-10-01" ])
    expect(described_class.groups(result.fetch(:items), "family").keys).to eq([ "Comments" ])
    expect(described_class.groups(result.fetch(:items), "actor").keys).to eq([ "Avery Morgan" ])
    expect(described_class.groups(result.fetch(:items), "day").keys).to eq([ "2026-10-01" ])
    expect(page(since: "2027-01-01").fetch(:items)).to be_empty
  end

  it "removes source details and actors before filtering tombstones and omits restricted events" do
    items = page.fetch(:items)
    unavailable = items.select { |event| %w[deleted redacted].include?(event.fetch(:state)) }
    expect(unavailable.size).to eq(14)
    expect(unavailable).to all(include(actor: "Unavailable", details: {}, sourceUrl: nil))
    expect(items.map { |event| event.fetch(:state) }).not_to include("restricted")
    expect(page(actor: "Jules Chen").fetch(:items)).to all(include(state: "available"))
    expect(page(actor: "Unavailable").fetch(:items).size).to eq(14)
  end

  it "rejects tampered, oversized, cross-reader, changed-filter and expired resume links" do
    query = next_params(page)
    expect { page(cursor: "tampered") }.to raise_error(ArgumentError, /Resume link/)
    expect { page(cursor: "x" * 4097) }.to raise_error(ArgumentError, /Resume link/)
    expect { page(cursor: [ "invalid" ]) }.to raise_error(ArgumentError, /Resume link/)
    expect { page(query.merge("family" => "file")) }.to raise_error(ArgumentError, /Resume link/)
    other = create(:admin_user)
    expect { described_class.new(admin_user: other, params: query).page }.to raise_error(ArgumentError, /Resume link/)
    travel 2.hours do
      expect { page(query) }.to raise_error(ArgumentError, /Resume link/)
    end
  end

  it "validates filter inputs rather than silently changing the requested view" do
    [ { family: "unknown" }, { actor: "unknown" }, { group: "unknown" }, { since: "today" }, { since: "2026-02-30" } ].each do |query|
      expect { page(query) }.to raise_error(ArgumentError)
    end
    expect { described_class.new(admin_user: nil).page }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
