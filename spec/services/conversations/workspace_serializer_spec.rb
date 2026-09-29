# spec/services/conversations/workspace_serializer_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::WorkspaceSerializer do
  let(:admin) { create(:admin_user) }
  let(:conversation) { create(:conversation, public_id: "serializer-room", title: "Serializer room") }
  let(:membership) { create(:conversation_membership, admin_user: admin, conversation:, display_name: "You") }
  let!(:message) do
    create(
      :message,
      body: "Plain <strong>text</strong>",
      conversation:,
      conversation_membership: membership,
      public_id: "serializer-message",
      sequence: 1
    )
  end

  it "serializes stable public identity, canonical routes, plain text, and permissions" do
    create(:saved_message, conversation:, membership:, message:)
    create(:message_disposition, kind: "like", membership:, message:)
    reviewer = create(:conversation_membership, conversation:, display_name: "Reviewer", key: "reviewer")
    create(:message_disposition, kind: "question", membership: reviewer, message:)
    inbox = Conversations::Inbox.call(admin_user: admin)
    page = Conversations::MessagePage.call(conversation:)

    payload = described_class.call(inbox_entries: inbox, membership:, message_page: page)

    expect(payload.fetch(:inbox).sole).to include(
      memberCount: 2,
      messagesUrl: "/admin/conversations/serializer-room/messages.json",
      publicId: "serializer-room",
      showUrl: "/admin/conversations/serializer-room"
    )
    expect(payload.fetch(:selected).fetch(:messages).sole).to include(
      body: "Plain <strong>text</strong>",
      deepLinkUrl: "/admin/conversations/serializer-room#message-serializer-message",
      dispositions: {
        counts: { "like" => 1, "dislike" => 0, "question" => 1 },
        mine: "like"
      },
      dispositionUrl: "/admin/conversations/serializer-room/messages/serializer-message/disposition.json",
      editable: true,
      own: true,
      publicId: "serializer-message",
      saved: true,
      savedUrl: "/admin/conversations/serializer-room/messages/serializer-message/saved.json"
    )
    expect(payload.fetch(:selected)).to include(
      draftNamespace: membership.key,
      participants: [
        { current: false, displayName: "Reviewer", key: reviewer.key },
        { current: true, displayName: "You", key: membership.key }
      ],
      scheduledMessagesUrl: "/admin/conversations/serializer-room/scheduled_messages",
      presence: {
        channel: "ConversationPresenceChannel",
        heartbeatIntervalMs: 15_000,
        typingIdleMs: 3_000
      },
      realtime: include(
        channel: "ConversationChannel",
        latestSequence: 1,
        version: 0
      )
    )
    expect(Time.iso8601(payload.dig(:selected, :realtime, :serverAt))).to be_present
    expect(payload.fetch(:savedMessagesUrl)).to eq("/admin/conversations/saved")
    expect(payload.fetch(:searchUrl)).to eq("/admin/conversations/search")
  end


  it "serializes canonical replies and structured mention identities" do
    mentioned = create(:conversation_membership, conversation:, display_name: "Riley Chen", key: "riley-chen")
    reply = Conversations::CreateMessage.call(
      body: "Thanks @Riley Chen",
      conversation:,
      membership:,
      mentioned_memberships: [ mentioned ],
      reply_to: message
    )

    payload = described_class.message(message: reply, membership:)

    expect(payload.fetch(:mentions)).to eq([ { memberKey: "riley-chen", text: "@Riley Chen" } ])
    expect(payload.fetch(:replyTo)).to include(
      authorName: "You",
      body: "Plain <strong>text</strong>",
      publicId: "serializer-message",
      withdrawn: false
    )
  end

  it "serializes the canonical changed-message representation independently of page position" do
    message.update!(body: "Edited", edited_at: Time.current)

    expect(described_class.message(message:, membership:)).to include(
      body: "Edited",
      edited: true,
      publicId: "serializer-message",
      saved: false
    )
  end
end
