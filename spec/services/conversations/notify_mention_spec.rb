# spec/services/conversations/notify_mention_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::NotifyMention, database_cleaner: :truncation do
  include ActiveJob::TestHelper

  let(:conversation) { create(:conversation, name: "Release coordination", public_id: "release-coordination") }
  let(:author) { create(:conversation_membership, conversation:, display_name: "Maya Ortiz") }
  let(:recipient) { create(:conversation_membership, conversation:, display_name: "Riley Chen") }
  let(:message) do
    create(
      :message,
      body: "Private details that do not belong in the notification projection",
      conversation:,
      conversation_membership: author,
      public_id: "mention-message",
      sequence: 1
    )
  end

  it "projects a committed structured mention into one recipient-specific Noticed notification" do
    mention = nil
    expect do
      ActiveRecord::Base.transaction do
        mention = build(:message_mention, conversation:, mentioned_membership: recipient, message:)
        mention.save!
        expect(recipient.admin_user.notifications.reload).to be_empty
      end
    end.to change(Noticed::Notification, :count).by(1)

    notification = recipient.admin_user.notifications.includes(:event).sole
    expect(notification).to be_a(ConversationMentionNotifier::Notification)
    expect(notification.event).to be_a(ConversationMentionNotifier)
    expect(notification.record).to eq(message)
    expect(notification.recipient).to eq(recipient.admin_user)
    expect(notification.params).to include(
      body: "Maya Ortiz mentioned you in Release coordination.",
      deep_link: "/admin/conversations/release-coordination#message-mention-message",
      kind: "conversation",
      subject: "You were mentioned"
    )
    expect(notification.params.fetch(:body)).not_to include(message.body)
    expect(mention).to be_persisted
  end

  it "delivers the existing Activity Center envelope over Cable as a best-effort enhancement" do
    expect do
      perform_enqueued_jobs do
        create(:message_mention, conversation:, mentioned_membership: recipient, message:)
      end
    end.to have_broadcasted_to(ActivityCenterChannel.broadcasting_for(recipient.admin_user)).with(
      type: "notification",
      notification: hash_including(
        body: "Maya Ortiz mentioned you in Release coordination.",
        deepLink: "/admin/conversations/release-coordination#message-mention-message",
        kind: "conversation",
        read: false,
        subject: "You were mentioned"
      )
    )
  end

  it "does not duplicate an existing recipient projection when retried" do
    mention = create(:message_mention, conversation:, mentioned_membership: recipient, message:)

    expect do
      expect(described_class.call(mention:)).to eq(recipient.admin_user.notifications.sole)
    end.not_to change(Noticed::Notification, :count)
  end

  it "keeps legacy participants outside the authenticated notification projection" do
    legacy = create(:conversation_membership, :legacy, conversation:, display_name: "Legacy Operator")

    expect do
      create(:message_mention, conversation:, mentioned_membership: legacy, message:)
    end.not_to change(Noticed::Notification, :count)
  end

  it "does not roll back durable mention truth when notification projection fails" do
    allow(described_class).to receive(:call).and_raise(Noticed::ValidationError, "projection failed")
    allow(Rails.error).to receive(:report)

    mention = create(:message_mention, conversation:, mentioned_membership: recipient, message:)

    expect(mention).to be_persisted
    expect(Rails.error).to have_received(:report).with(
      instance_of(Noticed::ValidationError),
      context: { message_mention_id: mention.id },
      handled: true
    )
  end
end
