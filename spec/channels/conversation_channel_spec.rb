# spec/channels/conversation_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConversationChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }
  let(:conversation) { create(:conversation) }
  let!(:membership) { create(:conversation_membership, admin_user:, conversation:) }

  before { stub_connection current_admin_user: admin_user }

  it "authorizes a durable member, streams only that conversation, and transmits a canonical snapshot" do
    message = create(:message, conversation:, conversation_membership: membership, sequence: 4)
    conversation.update!(realtime_version: 7)

    subscribe(conversation_public_id: conversation.public_id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(conversation)
    expect(transmissions.last).to include(
      "conversationPublicId" => conversation.public_id,
      "kind" => "snapshot",
      "latestSequence" => message.sequence,
      "version" => 7
    )
    expect(Time.iso8601(transmissions.last.fetch("serverAt"))).to be_present
  end

  it "rejects missing, non-member, and cross-user subscriptions without leaking a snapshot" do
    foreign_conversation = create(:conversation)
    create(:conversation_membership, conversation: foreign_conversation)

    subscribe(conversation_public_id: foreign_conversation.public_id)
    expect(subscription).to be_rejected
    expect(transmissions).to be_empty

    subscribe(conversation_public_id: "missing")
    expect(subscription).to be_rejected
    expect(transmissions).to be_empty
  end

  it "returns a fresh snapshot when a connected client reconciles after missing events" do
    subscribe(conversation_public_id: conversation.public_id)
    conversation.update!(realtime_version: 3)
    create(:message, conversation:, conversation_membership: membership, sequence: 2)

    perform :reconcile

    expect(transmissions.last).to include("latestSequence" => 2, "version" => 3)
  end
end
