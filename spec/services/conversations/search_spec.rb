# spec/services/conversations/search_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::Search do
  let(:admin) { create(:admin_user) }

  it "searches authorized conversation metadata and visible message bodies case-insensitively" do
    title_match = create(:conversation, title: "Release Planning", topic: "Shipping")
    title_membership = create(:conversation_membership, admin_user: admin, conversation: title_match)
    body_match = create(:conversation, title: "Operations", topic: "Handoffs")
    body_membership = create(:conversation_membership, admin_user: admin, conversation: body_match)
    message = create(
      :message,
      body: "The RELEASE candidate passed verification.",
      conversation: body_match,
      conversation_membership: body_membership
    )

    result = described_class.call(admin_user: admin, query: "  release  ")

    expect(result.query).to eq("release")
    expect(result.entries).to include(
      have_attributes(kind: :conversation, conversation: title_match, message: nil),
      have_attributes(kind: :message, conversation: body_match, message:)
    )
    expect(title_membership).to be_persisted
  end

  it "authorizes every result through authenticated membership and never searches withdrawn bodies" do
    visible_conversation = create(:conversation, title: "Visible room")
    visible_membership = create(:conversation_membership, admin_user: admin, conversation: visible_conversation)
    withdrawn = create(
      :message,
      body: "classified needle",
      conversation: visible_conversation,
      conversation_membership: visible_membership,
      withdrawn_at: Time.current
    )
    hidden_conversation = create(:conversation, title: "Needle strategy")
    hidden_membership = create(:conversation_membership, conversation: hidden_conversation)
    hidden_message = create(
      :message,
      body: "needle outside membership",
      conversation: hidden_conversation,
      conversation_membership: hidden_membership
    )

    result = described_class.call(admin_user: admin, query: "needle")

    expect(result.entries).to be_empty
    expect(result.entries.map(&:message)).not_to include(withdrawn, hidden_message)
  end

  it "treats SQL wildcard characters literally" do
    conversation = create(:conversation, title: "Percent room")
    membership = create(:conversation_membership, admin_user: admin, conversation:)
    literal = create(:message, body: "Capacity is 100%", conversation:, conversation_membership: membership)
    create(:message, body: "Capacity is full", conversation:, conversation_membership: membership)

    result = described_class.call(admin_user: admin, query: "%")

    expect(result.entries.map(&:message)).to eq([ literal ])
  end

  it "bounds normalized input and results with deterministic newest-first ordering" do
    conversation = create(:conversation, title: "Operations")
    membership = create(:conversation_membership, admin_user: admin, conversation:)
    base_time = Time.zone.parse("2026-09-28 12:00:00")
    messages = 52.times.map do |index|
      create(
        :message,
        body: "bounded result #{index}",
        conversation:,
        conversation_membership: membership,
        created_at: base_time + index.seconds,
        sequence: index + 1
      )
    end

    result = described_class.call(admin_user: admin, query: "bounded#{" " * 120}")

    expect(result.query.length).to be <= described_class::MAX_QUERY_LENGTH
    expect(result.entries.length).to eq(described_class::LIMIT)
    expect(result.entries.map(&:message)).to eq(messages.last(described_class::LIMIT).reverse)
  end

  it "returns no results for a blank or non-string query" do
    expect(described_class.call(admin_user: admin, query: "  ").entries).to be_empty
    expect(described_class.call(admin_user: admin, query: [ "unsafe" ]).entries).to be_empty
  end
end
