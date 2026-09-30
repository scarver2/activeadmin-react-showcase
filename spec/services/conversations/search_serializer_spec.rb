# spec/services/conversations/search_serializer_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::SearchSerializer do
  let(:admin) { create(:admin_user) }
  let(:conversation) { create(:conversation, public_id: "search-room", title: "Search room") }
  let(:membership) { create(:conversation_membership, admin_user: admin, conversation:, display_name: "You") }
  let!(:message) do
    create(
      :message,
      body: "Needle in a durable message",
      conversation:,
      conversation_membership: membership,
      public_id: "search-message",
      sequence: 7
    )
  end

  it "serializes a bounded canonical deep link through the matching message" do
    result = Conversations::Search.call(admin_user: admin, query: "needle")

    payload = described_class.call(result:)

    expect(payload).to include(limit: Conversations::Search::LIMIT, query: "needle")
    expect(payload.fetch(:results).sole).to include(
      authorName: "You",
      conversationPublicId: "search-room",
      kind: :message,
      messagePublicId: "search-message",
      summary: "Needle in a durable message",
      url: "/admin/conversations/search-room?before=8#message-search-message"
    )
  end
end
