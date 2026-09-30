# spec/channels/conversation_presence_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConversationPresenceChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }
  let(:conversation) { create(:conversation) }
  let!(:membership) do
    create(:conversation_membership, admin_user:, conversation:, display_name: "Release Lead")
  end
  let(:clock) { [ 0.0 ] }
  let(:registry) { Conversations::PresenceRegistry.new(clock: -> { clock.fetch(0) }) }

  before do
    described_class.registry = registry
    stub_connection current_admin_user: admin_user
  end

  after { described_class.registry = Conversations::PresenceRegistry.new }

  it "authorizes only a durable member and streams presence separately from conversation truth" do
    subscribe(conversation_public_id: conversation.public_id, session_id: "release-tab-one-1")

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(conversation)
    expect(registry.snapshot(conversation_id: conversation.id)).to eq(online: [ "Release Lead" ], typing: [])

    perform :reconcile
    expect(transmissions.last).to include(
      "conversationPublicId" => conversation.public_id,
      "kind" => "presence",
      "online" => [ "Release Lead" ],
      "typing" => []
    )
  end

  it "rejects missing membership and malformed session identity without leaking state" do
    foreign = create(:conversation)
    create(:conversation_membership, conversation: foreign)

    subscribe(conversation_public_id: foreign.public_id, session_id: "foreign-tab-one-1")
    expect(subscription).to be_rejected
    expect(transmissions).to be_empty

    subscribe(conversation_public_id: conversation.public_id, session_id: "short")
    expect(subscription).to be_rejected
    expect(transmissions).to be_empty
    expect(registry.snapshot(conversation_id: conversation.id)).to eq(online: [], typing: [])
  end

  it "publishes bounded typing state, ignores malformed actions, and cleans up on unsubscribe" do
    subscribe(conversation_public_id: conversation.public_id, session_id: "release-tab-one-1")

    perform :typing, active: true
    expect(registry.snapshot(conversation_id: conversation.id).fetch(:typing)).to eq([ "Release Lead" ])

    perform :typing, active: "true"
    expect(registry.snapshot(conversation_id: conversation.id).fetch(:typing)).to eq([ "Release Lead" ])

    unsubscribe
    expect(registry.snapshot(conversation_id: conversation.id)).to eq(online: [], typing: [])
  end

  it "keeps ephemeral channel actions out of persisted conversation truth" do
    counts = -> { [ Conversation.count, ConversationMembership.count, Message.count, conversation.reload.realtime_version ] }
    before = counts.call

    subscribe(conversation_public_id: conversation.public_id, session_id: "release-tab-one-1")
    perform :typing, active: true
    perform :heartbeat
    perform :reconcile
    unsubscribe

    expect(counts.call).to eq(before)
  end

  it "contains Cable delivery failures without changing registry state" do
    allow(described_class).to receive(:broadcast_to).and_raise(IOError, "Cable unavailable")
    allow(Rails.logger).to receive(:warn)

    expect do
      subscribe(conversation_public_id: conversation.public_id, session_id: "release-tab-one-1")
      perform :typing, active: true
    end.not_to raise_error
    expect(registry.snapshot(conversation_id: conversation.id)).to eq(
      online: [ "Release Lead" ],
      typing: [ "Release Lead" ]
    )
    expect(Rails.logger).to have_received(:warn).with(/Conversation presence broadcast failed/).at_least(:once)
  end
end
