# spec/requests/admin/conversations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin conversations" do
  let(:admin) { create(:admin_user) }
  let(:conversation) { create(:conversation, public_id: "release-room", title: "Release room") }
  let(:membership) { create(:conversation_membership, admin_user: admin, conversation:, display_name: "You") }
  let(:other_member) { create(:conversation_membership, conversation:, display_name: "Release Lead") }
  let!(:other_message) do
    create(
      :message,
      body: "Review <script>alert('unsafe')</script> ✅\nsecond line",
      conversation:,
      conversation_membership: other_member,
      public_id: "other-message",
      sequence: 1
    )
  end

  before do
    membership
    sign_in admin
  end

  it "requires an authenticated administrator" do
    sign_out admin

    get admin_conversations_path

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "returns no feature surface while the rollout gate is disabled" do
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "false") do
      get admin_conversations_path

      expect(response).to have_http_status(:not_found)
    end
  end

  it "renders only the authenticated user's inbox and escapes plain-text messages" do
    hidden_conversation = create(:conversation, public_id: "hidden-room", title: "Hidden room")
    create(:conversation_membership, conversation: hidden_conversation)

    get admin_conversations_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Release room")
    expect(response.body).not_to include("Hidden room")

    get admin_conversation_path(conversation.public_id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("&lt;script&gt;alert(&#39;unsafe&#39;)&lt;/script&gt;")
    expect(response.body).not_to include("<script>alert")
  end

  it "returns 404 for an unauthorized public ID" do
    hidden = create(:conversation, public_id: "hidden-room")

    get admin_conversation_path(hidden.public_id)
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 for a missing public ID" do
    get admin_conversation_path("missing-room")

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 before mutating an unauthorized conversation" do
    hidden = create(:conversation, public_id: "hidden-room")

    post admin_conversation_messages_path(hidden.public_id), params: { message: { body: "Injected" } }
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 before reading an unauthorized conversation" do
    hidden = create(:conversation, public_id: "hidden-room")

    post admin_conversation_read_state_path(hidden.public_id, other_message.public_id)
    expect(response).to have_http_status(:not_found)
  end

  it "creates multiline emoji messages with PRG and advances the sender cursor atomically" do
    post admin_conversation_messages_path(conversation.public_id),
         params: { message: { body: "First line ✅\nSecond line" } }

    message = conversation.messages.order(:sequence).last
    expect(response).to redirect_to(admin_conversation_path(conversation.public_id))
    expect(message.body).to eq("First line ✅\nSecond line")
    expect(membership.reload.last_read_message).to eq(message)
  end

  it "rejects malformed message parameters with a bad request" do
    post admin_conversation_messages_path(conversation.public_id), params: {}

    expect(response).to have_http_status(:bad_request)
  end

  it "provides author-only edit and withdraw routes" do
    own_message = create(
      :message,
      conversation:,
      conversation_membership: membership,
      public_id: "own-message",
      sequence: 2
    )

    get edit_admin_conversation_message_path(conversation.public_id, own_message.public_id)
    expect(response).to have_http_status(:ok)

    patch admin_conversation_message_path(conversation.public_id, own_message.public_id),
          params: { message: { body: "Edited body" } }
    expect(response).to redirect_to(admin_conversation_path(conversation.public_id))
    expect(own_message.reload).to have_attributes(body: "Edited body", edited_at: be_present)

    delete admin_conversation_withdraw_message_path(conversation.public_id, own_message.public_id)
    expect(response).to redirect_to(admin_conversation_path(conversation.public_id))
    expect(own_message.reload).to have_attributes(body: Message::WITHDRAWN_BODY, withdrawn_at: be_present)
  end

  it "returns 404 when a non-author opens the edit form" do
    get edit_admin_conversation_message_path(conversation.public_id, other_message.public_id)

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when a non-author submits an edit" do
    patch admin_conversation_message_path(conversation.public_id, other_message.public_id),
          params: { message: { body: "Injected" } }

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when a non-author withdraws a message" do
    delete admin_conversation_withdraw_message_path(conversation.public_id, other_message.public_id)

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when an author opens an expired edit form" do
    expired = expired_message

    get edit_admin_conversation_message_path(conversation.public_id, expired.public_id)

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when an author submits an expired edit" do
    expired = expired_message

    patch admin_conversation_message_path(conversation.public_id, expired.public_id),
          params: { message: { body: "Too late" } }

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when an author withdraws after the window" do
    expired = expired_message

    delete admin_conversation_withdraw_message_path(conversation.public_id, expired.public_id)

    expect(response).to have_http_status(:not_found)
  end

  it "moves explicit read state without allowing mark-unread to advance it" do
    own_message = create(
      :message,
      conversation:,
      conversation_membership: membership,
      public_id: "own-message",
      sequence: 2
    )

    post admin_conversation_read_state_path(conversation.public_id, own_message.public_id)
    expect(membership.reload.last_read_message).to eq(own_message)

    delete admin_conversation_unread_state_path(conversation.public_id, other_message.public_id)
    expect(membership.reload.last_read_message).to be_nil

    delete admin_conversation_unread_state_path(conversation.public_id, own_message.public_id)
    expect(membership.reload.last_read_message).to be_nil
  end

  it "requires a valid CSRF token when forgery protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post admin_conversation_messages_path(conversation.public_id),
         params: { message: { body: "No token" } }

    expect(response).to have_http_status(:unprocessable_content)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  def expired_message
    create(
      :message,
      conversation:,
      conversation_membership: membership,
      created_at: 16.minutes.ago,
      public_id: "expired-message",
      sequence: 2
    )
  end
end
