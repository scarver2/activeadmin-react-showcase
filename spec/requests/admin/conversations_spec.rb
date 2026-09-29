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

      sign_in admin
      get saved_admin_conversations_path
      expect(response).to have_http_status(:not_found)

      sign_in admin
      post admin_conversation_saved_message_path(conversation.public_id, other_message.public_id)
      expect(response).to have_http_status(:not_found)
      expect(membership.saved_messages).to be_empty
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
    create(:message_disposition, kind: "like", membership:, message: other_message)
    create(:message_disposition, kind: "question", message: other_message)

    get admin_conversation_messages_path(conversation.public_id, format: :json)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    selected = response.parsed_body.fetch("selected")
    expect(selected).to include("publicId" => "release-room", "olderCursor" => nil)
    expect(selected.fetch("messages").sole).to include(
      "body" => "Review <script>alert('unsafe')</script> ✅\nsecond line",
      "dispositions" => {
        "counts" => { "dislike" => 0, "like" => 1, "question" => 1 },
        "mine" => "like"
      },
      "dispositionUrl" => admin_conversation_message_disposition_path(
        conversation.public_id,
        other_message.public_id,
        format: :json
      ),
      "publicId" => "other-message"
    )
  end

  it "sets, replays, changes, and removes only the authenticated membership disposition" do
    peer_disposition = create(:message_disposition, kind: "question", membership: other_member, message: other_message)

    post admin_conversation_message_disposition_path(conversation.public_id, other_message.public_id, format: :json),
         params: { disposition: { kind: "like", membership_id: other_member.id } },
         as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("message").fetch("dispositions")).to eq(
      "counts" => { "dislike" => 0, "like" => 1, "question" => 1 },
      "mine" => "like"
    )
    expect(membership.message_dispositions.sole.kind).to eq("like")
    expect(peer_disposition.reload.kind).to eq("question")

    expect do
      post admin_conversation_message_disposition_path(conversation.public_id, other_message.public_id),
           params: { disposition: { kind: "like" } }
    end.not_to change(MessageDisposition, :count)
    expect(response).to redirect_to(
      admin_conversation_path(
        conversation.public_id,
        anchor: "message-#{other_message.public_id}",
        before: other_message.sequence + 1
      )
    )

    post admin_conversation_message_disposition_path(conversation.public_id, other_message.public_id, format: :json),
         params: { disposition: { kind: "dislike" } },
         as: :json
    expect(response.parsed_body.dig("message", "dispositions")).to eq(
      "counts" => { "dislike" => 1, "like" => 0, "question" => 1 },
      "mine" => "dislike"
    )

    delete admin_conversation_message_disposition_path(conversation.public_id, other_message.public_id, format: :json),
           as: :json
    expect(response.parsed_body.dig("message", "dispositions")).to eq(
      "counts" => { "dislike" => 0, "like" => 0, "question" => 1 },
      "mine" => nil
    )
    expect(membership.message_dispositions.reload).to be_empty
  end

  it "rejects unsupported and unauthorized disposition mutations" do
    post admin_conversation_message_disposition_path(conversation.public_id, other_message.public_id, format: :json),
         params: { disposition: { kind: "approval" } },
         as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq("error" => "Choose Like, Dislike, or Question.")

    hidden_membership = create(:conversation_membership)
    hidden_message = create(:message, conversation: hidden_membership.conversation)
    post admin_conversation_message_disposition_path(
      hidden_membership.conversation.public_id,
      hidden_message.public_id
    ), params: { disposition: { kind: "like" } }
    expect(response).to have_http_status(:not_found)
    expect(hidden_message.dispositions).to be_empty
  end

  it "renders accessible disposition state and counts without JavaScript" do
    create(:message_disposition, kind: "like", membership:, message: other_message)
    create(:message_disposition, kind: "question", message: other_message)

    get admin_conversation_path(conversation.public_id)

    document = Nokogiri::HTML(response.body)
    like = document.at_css('button[aria-label="Like message by Release Lead, 1 total"]')
    dislike = document.at_css('button[aria-label="Dislike message by Release Lead, 0 total"]')
    question = document.at_css('button[aria-label="Question message by Release Lead, 1 total"]')
    expect(like["aria-pressed"]).to eq("true")
    expect(dislike["aria-pressed"]).to eq("false")
    expect(question["aria-pressed"]).to eq("false")
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

  it "resolves reply and mention identities only inside the authorized conversation" do
    mentioned = create(:conversation_membership, conversation:, display_name: "Riley Chen", key: "riley-chen")

    post admin_conversation_messages_path(conversation.public_id, format: :json),
         params: {
           message: {
             body: "Thanks @Riley Chen",
             mentioned_member_keys: [ "riley-chen" ],
             public_id: "26ae96bf-7b68-4da1-99e1-e0f0d243a1fb",
             reply_to_public_id: other_message.public_id
           }
         },
         as: :json

    expect(response).to have_http_status(:created)
    payload = response.parsed_body.fetch("message")
    expect(payload.fetch("mentions")).to eq([ { "memberKey" => "riley-chen", "text" => "@Riley Chen" } ])
    expect(payload.fetch("replyTo")).to include(
      "authorName" => "Release Lead",
      "publicId" => "other-message"
    )
  end

  it "replays the same ordinary client send once and rejects changed content" do
    parameters = {
      message: {
        body: "Network-safe send",
        public_id: "0b1af2eb-58ce-42c1-953b-a14c04cbd18d"
      }
    }

    2.times do
      post admin_conversation_messages_path(conversation.public_id, format: :json), params: parameters, as: :json
      expect(response).to have_http_status(:created)
    end
    expect(conversation.messages.where(public_id: parameters.dig(:message, :public_id)).count).to eq(1)

    parameters[:message][:body] = "Changed replay"
    post admin_conversation_messages_path(conversation.public_id, format: :json), params: parameters, as: :json
    expect(response).to have_http_status(:conflict)
  end

  it "replays an attachment send through the canonical JSON endpoint without duplicating storage" do
    public_id = "4017232c-8681-49d2-a40b-181f51115e9b"

    2.times do
      post admin_conversation_messages_path(conversation.public_id, format: :json),
           params: {
             message: {
               attachment: fixture_file_upload("sample.txt", "text/plain"),
               body: "Network-safe attachment",
               public_id:
             }
           }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("message", "attachment", "filename")).to eq("sample.txt")
    end

    message = conversation.messages.find_by!(public_id:)
    expect(conversation.messages.where(public_id:).count).to eq(1)
    expect(MessageAttachment.where(message:).count).to eq(1)
  end

  it "rejects forged cross-conversation reply and mention identifiers" do
    outsider = create(:conversation_membership, display_name: "Hidden person", key: "hidden-person")
    foreign_message = create(
      :message,
      conversation: outsider.conversation,
      conversation_membership: outsider,
      public_id: "hidden-message"
    )

    post admin_conversation_messages_path(conversation.public_id),
         params: { message: { body: "Forged", reply_to_public_id: foreign_message.public_id } }
    expect(response).to have_http_status(:not_found)

    sign_in admin
    post admin_conversation_messages_path(conversation.public_id),
         params: { message: { body: "Forged", mentioned_member_keys: [ outsider.key ] } }
    expect(response).to have_http_status(:not_found)
  end

  it "renders participants, reply quoting, mention treatment, exact time, and no-JavaScript reply controls" do
    mentioned = create(:conversation_membership, conversation:, display_name: "Riley Chen", key: "riley-chen")
    reply = Conversations::CreateMessage.call(
      body: "Thanks @Riley Chen",
      conversation:,
      membership:,
      mentioned_memberships: [ mentioned ],
      reply_to: other_message
    )

    get admin_conversation_path(conversation.public_id, reply_to: reply.public_id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "Conversation participants",
      "Replying to Release Lead",
      "Mention participants (optional)",
      "Exact send time",
      "data-member-key=\"riley-chen\"",
      "name=\"message[public_id]\"",
      "name=\"message[reply_to_public_id]\""
    )
  end

  it "creates one bounded attachment and exposes only the membership-guarded canonical URL" do
    upload = fixture_file_upload("sample.txt", "text/plain")

    post admin_conversation_messages_path(conversation.public_id, format: :json),
         params: { message: { attachment: upload, body: "Review the attached notes" } }

    expect(response).to have_http_status(:created)
    message_payload = response.parsed_body.fetch("message")
    attachment_payload = message_payload.fetch("attachment")
    message = conversation.messages.order(:sequence).last
    attachment = message.attachment
    expect(attachment_payload).to include(
      "contentType" => "text/plain",
      "filename" => "sample.txt",
      "inline" => false
    )
    expect(attachment_payload.fetch("url")).to eq(
      admin_conversation_message_attachment_path(conversation.public_id, message.public_id, attachment.public_id)
    )
    expect(response.body).not_to include("rails/active_storage", "signed_id")

    get attachment_payload.fetch("url")
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.headers).to include(
      "Content-Disposition" => match(/attachment/),
      "Content-Security-Policy" => "default-src 'none'; sandbox",
      "X-Content-Type-Options" => "nosniff"
    )
    expect(response.body).to eq(File.binread(file_fixture("sample.txt")))
  end

  it "does not permit another administrator to download or preview a conversation attachment" do
    message = Conversations::CreateMessage.call(
      attachment: fixture_file_upload("sample.txt", "text/plain"),
      body: "Private attachment",
      conversation:,
      membership:
    )
    attachment = message.attachment
    sign_out admin
    sign_in create(:admin_user)

    get admin_conversation_message_attachment_path(
      conversation.public_id,
      message.public_id,
      attachment.public_id
    )

    expect(response).to have_http_status(:not_found)
  end

  it "hides an attachment behind a withdrawn tombstone" do
    message = Conversations::CreateMessage.call(
      attachment: fixture_file_upload("sample.txt", "text/plain"),
      body: "Withdraw this attachment",
      conversation:,
      membership:
    )
    attachment = message.attachment
    Conversations::WithdrawMessage.call(message:, membership:)

    get admin_conversation_messages_path(conversation.public_id, format: :json)
    expect(response).to have_http_status(:ok)
    withdrawn = response.parsed_body.fetch("selected").fetch("messages").find { |item| item["publicId"] == message.public_id }
    expect(withdrawn).to include("attachment" => nil, "body" => Message::WITHDRAWN_BODY)

    get admin_conversation_message_attachment_path(
      conversation.public_id,
      message.public_id,
      attachment.public_id
    )

    expect(response).to have_http_status(:not_found)
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

  it "saves and removes a message privately with PRG" do
    post admin_conversation_saved_message_path(conversation.public_id, other_message.public_id)

    expect(response).to redirect_to(
      admin_conversation_path(conversation.public_id, anchor: "message-#{other_message.public_id}")
    )
    expect(membership.saved_messages.sole.message).to eq(other_message)

    post admin_conversation_saved_message_path(conversation.public_id, other_message.public_id)
    expect(membership.saved_messages.reload.count).to eq(1)

    delete admin_conversation_saved_message_path(conversation.public_id, other_message.public_id)
    expect(response).to redirect_to(
      admin_conversation_path(conversation.public_id, anchor: "message-#{other_message.public_id}")
    )
    expect(membership.saved_messages.reload).to be_empty
  end

  it "returns canonical private saved state for JSON mutations" do
    post admin_conversation_saved_message_path(conversation.public_id, other_message.public_id, format: :json), as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "ok" => true,
      "message" => include(
        "publicId" => other_message.public_id,
        "saved" => true,
        "savedUrl" => admin_conversation_saved_message_path(
          conversation.public_id,
          other_message.public_id,
          format: :json
        )
      )
    )

    delete admin_conversation_saved_message_path(conversation.public_id, other_message.public_id, format: :json), as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("message", "saved")).to be(false)
  end

  it "renders only the current membership's saved messages with canonical deep links" do
    create(:saved_message, conversation:, membership:, message: other_message)
    other_membership = create(:conversation_membership, conversation:)
    hidden_message = create(:message, conversation:, sequence: 2, body: "Other member secret")
    create(:saved_message, conversation:, membership: other_membership, message: hidden_message)

    get saved_admin_conversations_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Release room")
    expect(response.body).to include("other-message")
    expect(response.body).not_to include("Other member secret")
  end

  it "renders deterministic older and newer saved-message navigation without JavaScript" do
    stub_const("Conversations::SavedMessages::LIMIT", 1)
    older = create(:saved_message, conversation:, membership:, message: other_message, created_at: 1.day.ago)
    newer_message = create(:message, conversation:, sequence: 2, body: "Newest private save")
    newer = create(:saved_message, conversation:, membership:, message: newer_message)

    get saved_admin_conversations_path
    expect(Nokogiri::HTML(response.body).text).to include(newer.message.body)
    expect(Nokogiri::HTML(response.body).text).not_to include(older.message.body)
    older_url = Nokogiri::HTML(response.body).css("a").find { |link| link.text.include?("Older saved messages") }["href"]

    get older_url
    expect(Nokogiri::HTML(response.body).text).to include(older.message.body)
    expect(Nokogiri::HTML(response.body).text).not_to include(newer.message.body)
    newer_url = Nokogiri::HTML(response.body).css("a").find { |link| link.text.include?("Newer saved messages") }["href"]

    get newer_url
    expect(Nokogiri::HTML(response.body).text).to include(newer.message.body)
    expect(Nokogiri::HTML(response.body).text).not_to include(older.message.body)
  end

  it "shows only the durable tombstone after a saved message is withdrawn" do
    own_message = create(
      :message,
      body: "Sensitive launch details",
      conversation:,
      conversation_membership: membership,
      public_id: "saved-sensitive-message",
      sequence: 2
    )
    create(:saved_message, conversation:, membership:, message: own_message)
    Conversations::WithdrawMessage.call(message: own_message, membership:)

    get saved_admin_conversations_path

    expect(response.body).to include(Message::WITHDRAWN_BODY)
    expect(response.body).not_to include("Sensitive launch details")
  end

  it "returns 404 before saving a message from an unauthorized conversation" do
    hidden_membership = create(:conversation_membership)
    hidden_message = create(:message, conversation: hidden_membership.conversation)

    post admin_conversation_saved_message_path(hidden_membership.conversation.public_id, hidden_message.public_id)

    expect(response).to have_http_status(:not_found)
    expect(hidden_message.saved_messages).to be_empty
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
