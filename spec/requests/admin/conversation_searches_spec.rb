# spec/requests/admin/conversation_searches_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin conversation searches" do
  let(:admin) { create(:admin_user) }
  let(:conversation) { create(:conversation, public_id: "search-room", title: "Search room") }
  let(:membership) { create(:conversation_membership, admin_user: admin, conversation:, display_name: "You") }
  let!(:message) do
    create(
      :message,
      body: "Accessibility verification is ready",
      conversation:,
      conversation_membership: membership,
      public_id: "matching-message",
      sequence: 7
    )
  end

  before { sign_in admin }

  it "requires an authenticated administrator" do
    sign_out admin

    get admin_conversation_search_path, params: { q: "accessibility" }

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "renders a substantive no-JavaScript search result with a canonical message deep link" do
    get admin_conversation_search_path, params: { q: "ACCESSIBILITY" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("1 result", "Accessibility verification is ready")
    expect(response.body).to include(
      "/admin/conversations/search-room?before=8#message-matching-message"
    )
  end

  it "returns a canonical JSON representation" do
    get admin_conversation_search_path(format: :json), params: { q: "accessibility" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to include("limit" => Conversations::Search::LIMIT, "query" => "accessibility")
    expect(response.parsed_body.fetch("results").sole).to include(
      "conversationPublicId" => "search-room",
      "kind" => "message",
      "messagePublicId" => "matching-message"
    )
  end

  it "does not return unauthorized conversations or withdrawn bodies" do
    withdrawn = create(
      :message,
      body: "private needle historical body",
      conversation:,
      conversation_membership: membership,
      sequence: 8,
      withdrawn_at: Time.current
    )
    hidden_conversation = create(:conversation, title: "Private needle")
    hidden_membership = create(:conversation_membership, conversation: hidden_conversation)
    create(
      :message,
      body: "private needle",
      conversation: hidden_conversation,
      conversation_membership: hidden_membership
    )

    get admin_conversation_search_path, params: { q: "private needle" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No authorized conversation results")
    expect(response.body).not_to include(withdrawn.body, hidden_conversation.title)
  end

  it "renders an instructive empty state without querying all messages" do
    get admin_conversation_search_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Enter a search term")
    expect(response.body).not_to include(message.body)
  end

  it "returns no feature surface while the rollout gate is disabled" do
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "false") do
      get admin_conversation_search_path, params: { q: "accessibility" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
