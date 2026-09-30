# spec/services/conversations/presence_registry_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::PresenceRegistry do
  let(:conversation) { create(:conversation) }
  let(:first_member) { create(:conversation_membership, conversation:, display_name: "Release Lead") }
  let(:second_member) { create(:conversation_membership, conversation:, display_name: "You") }
  let(:clock) { [ 0.0 ] }
  let(:registry) { described_class.new(clock: -> { clock.fetch(0) }) }

  it "collapses multiple tabs by membership and removes only the departing session" do
    registry.join(conversation_id: conversation.id, session_id: "release-tab-one-1", membership: first_member)
    duplicate = registry.join(conversation_id: conversation.id, session_id: "release-tab-two-2", membership: first_member)
    registry.join(conversation_id: conversation.id, session_id: "viewer-tab-one-11", membership: second_member)

    expect(duplicate.changed).to be(false)
    expect(registry.snapshot(conversation_id: conversation.id)).to eq(
      online: [ "Release Lead", "You" ],
      typing: []
    )
    registry.typing(conversation_id: conversation.id, session_id: "release-tab-one-1", active: true)
    registry.typing(conversation_id: conversation.id, session_id: "release-tab-two-2", active: true)
    registry.typing(conversation_id: conversation.id, session_id: "release-tab-one-1", active: false)
    expect(registry.snapshot(conversation_id: conversation.id).fetch(:typing)).to eq([ "Release Lead" ])

    expect(registry.leave(conversation_id: conversation.id, session_id: "release-tab-one-1").changed).to be(false)
    expect(registry.snapshot(conversation_id: conversation.id).fetch(:online)).to eq([ "Release Lead", "You" ])
  end

  it "bounds typing and online state with independent expiries and heartbeat revival" do
    registry.join(conversation_id: conversation.id, session_id: "release-tab-one-1", membership: first_member)
    expect(registry.typing(conversation_id: conversation.id, session_id: "release-tab-one-1", active: true).snapshot)
      .to include(typing: [ "Release Lead" ])

    clock[0] = 6.0
    typing_expiry = registry.expire(conversation_id: conversation.id)
    expect(typing_expiry).to have_attributes(changed: true, snapshot: { online: [ "Release Lead" ], typing: [] })

    clock[0] = 46.0
    online_expiry = registry.expire(conversation_id: conversation.id)
    expect(online_expiry).to have_attributes(changed: true, snapshot: { online: [], typing: [] })

    revived = registry.heartbeat(
      conversation_id: conversation.id,
      session_id: "release-tab-one-1",
      membership: first_member
    )
    expect(revived).to have_attributes(changed: true, snapshot: { online: [ "Release Lead" ], typing: [] })
  end

  it "never persists ephemeral presence or typing state" do
    counts = -> { [ Conversation.count, ConversationMembership.count, Message.count ] }
    first_member
    before = counts.call

    registry.join(conversation_id: conversation.id, session_id: "release-tab-one-1", membership: first_member)
    registry.typing(conversation_id: conversation.id, session_id: "release-tab-one-1", active: true)
    registry.heartbeat(conversation_id: conversation.id, session_id: "release-tab-one-1", membership: first_member)
    registry.leave(conversation_id: conversation.id, session_id: "release-tab-one-1")

    expect(counts.call).to eq(before)
  end
end
