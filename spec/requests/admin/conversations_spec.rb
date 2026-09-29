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
    expect(response.body).to include(
      'data-conversation-fallback="thread"',
      "Send a message",
      "Scheduled messages"
    )
  end

  it "returns a bounded canonical inbox JSON representation" do
    hidden_conversation = create(:conversation, public_id: "hidden-room", title: "Hidden room")
    create(:conversation_membership, conversation: hidden_conversation)

    get admin_conversations_path(format: :json)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body.fetch("inbox").pluck("publicId")).to eq([ "release-room" ])
    expect(response.parsed_body.fetch("selected")).to be_nil
  end

  it "returns a membership-authorized canonical message page from the explicit JSON endpoint" do
    get admin_conversation_messages_path(conversation.public_id, format: :json)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    selected = response.parsed_body.fetch("selected")
    expect(selected).to include("publicId" => "release-room", "olderCursor" => nil)
    expect(selected.fetch("messages").sole).to include(
      "body" => "Review <script>alert('unsafe')</script> ✅\nsecond line",
      "publicId" => "other-message"
    )
  end

  it "returns 404 JSON for an unauthorized canonical message page" do
    hidden = create(:conversation, public_id: "hidden-room")

    get admin_conversation_messages_path(hidden.public_id, format: :json)

    expect(response).to have_http_status(:not_found)
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

  it "creates through JSON and returns the canonical persisted message" do
    post admin_conversation_messages_path(conversation.public_id, format: :json),
         params: { message: { body: "JSON line ✅\nSecond line" } },
         as: :json

    expect(response).to have_http_status(:created)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to include("ok" => true)
    expect(response.parsed_body.fetch("message")).to include(
      "body" => "JSON line ✅\nSecond line",
      "own" => true,
      "sequence" => 2
    )
  end

  it "returns canonical validation errors as JSON" do
    post admin_conversation_messages_path(conversation.public_id, format: :json),
         params: { message: { body: "" } },
         as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body.fetch("error")).to match(/Body is too short/)
  end

  it "creates, renders, updates, and cancels only the signed-in author's scheduled messages" do
    other_admin = create(:admin_user)
    create(:conversation_membership, admin_user: other_admin, conversation:, legacy_identity: false)
    hidden = create(
      :scheduled_message,
      admin_user: other_admin,
      body: "Private scheduled body",
      conversation:,
      scheduled_for: 3.hours.from_now
    )

    expect do
      post admin_conversation_scheduled_messages_path(conversation.public_id),
           params: { scheduled_message: { body: "Future update ✅", scheduled_for: 2.hours.from_now.iso8601 } }
    end.to have_enqueued_job(DeliverScheduledMessageJob).and change(ScheduledMessage, :count).by(1)
    scheduled_message = ScheduledMessage.where(admin_user: admin).last
    expect(response).to redirect_to(admin_conversation_scheduled_messages_path(conversation.public_id))

    get admin_conversation_scheduled_messages_path(conversation.public_id)
    expect(response.body).to include("Future update ✅")
    expect(response.body).not_to include("Private scheduled body")

    get edit_admin_conversation_scheduled_message_path(conversation.public_id, scheduled_message.public_id)
    expect(response).to have_http_status(:ok)

    rescheduled_for = 4.hours.from_now
    patch admin_conversation_scheduled_message_path(conversation.public_id, scheduled_message.public_id),
          params: { scheduled_message: { body: "Rescheduled", scheduled_for: rescheduled_for.iso8601 } }
    expect(response).to redirect_to(admin_conversation_scheduled_messages_path(conversation.public_id))
    expect(scheduled_message.reload.body).to eq("Rescheduled")
    expect(scheduled_message.scheduled_for).to be_within(1.second).of(rescheduled_for)

    delete admin_conversation_scheduled_message_path(conversation.public_id, scheduled_message.public_id)
    expect(response).to redirect_to(admin_conversation_scheduled_messages_path(conversation.public_id))
    expect(scheduled_message.reload.state).to eq("cancelled")

    get edit_admin_conversation_scheduled_message_path(conversation.public_id, hidden.public_id)
    expect(response).to have_http_status(:not_found)
  end

  it "rejects malformed or past scheduled delivery input" do
    post admin_conversation_scheduled_messages_path(conversation.public_id), params: {}
    expect(response).to have_http_status(:bad_request)

    sign_in admin
    expect do
      post admin_conversation_scheduled_messages_path(conversation.public_id),
           params: { scheduled_message: { body: "Past", scheduled_for: 1.minute.ago.iso8601 } }
    end.not_to change(ScheduledMessage, :count)
    expect(response).to redirect_to(admin_conversation_scheduled_messages_path(conversation.public_id))
  end

  it "does not expose another author's scheduled message mutation routes" do
    other_admin = create(:admin_user)
    create(:conversation_membership, admin_user: other_admin, conversation:, legacy_identity: false)
    hidden = create(
      :scheduled_message,
      admin_user: other_admin,
      conversation:,
      scheduled_for: 3.hours.from_now
    )

    patch admin_conversation_scheduled_message_path(conversation.public_id, hidden.public_id),
          params: { scheduled_message: { body: "Forged", scheduled_for: 4.hours.from_now.iso8601 } }
    expect(response).to have_http_status(:not_found)

    sign_in admin
    delete admin_conversation_scheduled_message_path(conversation.public_id, hidden.public_id)
    expect(response).to have_http_status(:not_found)
    expect(hidden.reload.state).to eq("pending")
  end

  it "renders the canonical delivered message after its author withdraws it" do
    delivered_message = create(
      :message,
      author: membership,
      body: "Original scheduled secret",
      conversation:,
      public_id: "scheduled-canonical-message",
      sequence: 2
    )
    create(
      :scheduled_message,
      admin_user: admin,
      body: "Original scheduled secret",
      conversation:,
      delivered_at: 1.minute.ago,
      delivered_message:,
      delivery_public_id: delivered_message.public_id,
      scheduled_for: 2.minutes.ago,
      state: "delivered"
    )

    delete admin_conversation_withdraw_message_path(conversation.public_id, delivered_message.public_id)
    get admin_conversation_scheduled_messages_path(conversation.public_id)

    expect(response.body).to include(Message::WITHDRAWN_BODY)
    expect(response.body).not_to include("Original scheduled secret")
  end

  it "returns no scheduled mutation surface while the rollout gate is disabled" do
    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "false") do
      post admin_conversation_scheduled_messages_path(conversation.public_id),
           params: { scheduled_message: { body: "Hidden", scheduled_for: 1.hour.from_now.iso8601 } }

      expect(response).to have_http_status(:not_found)
    end
  end

  it "requires a valid CSRF token for scheduled mutations when forgery protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    post admin_conversation_scheduled_messages_path(conversation.public_id),
         params: { scheduled_message: { body: "No token", scheduled_for: 1.hour.from_now.iso8601 } }

    expect(response).to have_http_status(:unprocessable_content)
  ensure
    ActionController::Base.allow_forgery_protection = original
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

  it "returns canonical edited and withdrawn messages from JSON mutations" do
    own_message = create(
      :message,
      conversation:,
      conversation_membership: membership,
      public_id: "own-json-message",
      sequence: 2
    )

    patch admin_conversation_message_path(conversation.public_id, own_message.public_id, format: :json),
          params: { message: { body: "Canonical edit" } },
          as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("message")).to include("body" => "Canonical edit", "edited" => true)

    delete admin_conversation_withdraw_message_path(conversation.public_id, own_message.public_id, format: :json),
           as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("message")).to include(
      "body" => Message::WITHDRAWN_BODY,
      "withdrawn" => true
    )
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

  it "returns canonical JSON acknowledgements for read-state mutations" do
    post admin_conversation_read_state_path(conversation.public_id, other_message.public_id, format: :json), as: :json

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    expect(response.parsed_body).to eq("ok" => true)
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
