# spec/services/showcase/calm_attention_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::CalmAttention do
  let(:admin) { create(:admin_user) }

  def notification(owner: admin, kind: "fyi", priority: "normal")
    ActivityCenter::Create.call(admin_user: owner, attention_kind: kind, priority:, enqueue_delivery: false,
      attributes: { subject: "Review", body: "Context", kind: "account", deep_link: "/admin/accounts", occurred_at: Time.zone.parse("2026-09-30 12:00:00") })
  end

  it "prioritizes explicit action and high priority without promoting routine FYIs" do
    notification(kind: "requires_action", priority: "high")
    notification(kind: "requires_action")
    notification(priority: "high")
    notification(owner: create(:admin_user), kind: "requires_action", priority: "high")
    notification.update!(dismissed_at: Time.current)
    notification.update!(snoozed_until: 1.hour.from_now)
    groups = described_class.new(admin_user: admin).groups
    expect(groups.map { |group| group.fetch(:items).size }).to eq([ 1, 1, 1 ])
    expect(groups.first.fetch(:items).first.fetch(:action)).to eq("Review source")
    expect(groups.last.fetch(:items).first.fetch(:reason)).to include("no immediate action")
  end

  it "bounds visible work, preserves overflow and makes healthy state explicit" do
    5.times { notification(kind: "requires_action") }
    group = described_class.new(admin_user: admin).groups[1]
    expect(group.fetch(:items).size).to eq(3)
    expect(group.fetch(:remaining)).to eq(2)
    expect(described_class.new(admin_user: admin, scenario: "healthy").groups.flat_map { |entry| entry.fetch(:items) }).to eq([])
    expect(described_class.new(admin_user: admin, scenario: "exceptions").groups.map { |entry| entry.fetch(:items).size }).to eq([ 1, 1, 1 ])
    expect { described_class.new(admin_user: admin, scenario: "unknown") }.to raise_error(ArgumentError)
  end
end
