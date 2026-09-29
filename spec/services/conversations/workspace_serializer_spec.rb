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
    inbox = Conversations::Inbox.call(admin_user: admin)
    page = Conversations::MessagePage.call(conversation:)

    payload = described_class.call(inbox_entries: inbox, membership:, message_page: page)

    expect(payload.fetch(:inbox).sole).to include(
      messagesUrl: "/admin/conversations/serializer-room/messages.json",
      publicId: "serializer-room",
      showUrl: "/admin/conversations/serializer-room"
    )
    expect(payload.fetch(:selected).fetch(:messages).sole).to include(
      body: "Plain <strong>text</strong>",
      editable: true,
      own: true,
      publicId: "serializer-message",
      saved: true,
      savedUrl: "/admin/conversations/serializer-room/messages/serializer-message/saved.json"
    )
    expect(payload.fetch(:selected)).to include(
      draftNamespace: membership.key,
      scheduledMessagesUrl: "/admin/conversations/serializer-room/scheduled_messages"
    )
    expect(payload.fetch(:savedMessagesUrl)).to eq("/admin/conversations/saved")
    expect(payload.fetch(:searchUrl)).to eq("/admin/conversations/search")
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
