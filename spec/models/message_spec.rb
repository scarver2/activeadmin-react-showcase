# spec/models/message_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message do
  it "assigns a stable unique public identity on creation" do
    message = create(:message)

    expect(message.public_id).to match(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/)
    expect(message.reload.public_id).to eq(message.public_id)
  end

  it "requires the author membership to belong to the same conversation" do
    message = build(:message, conversation_membership: create(:conversation_membership))

    expect(message).not_to be_valid
    expect(message.errors[:conversation_membership]).to include("must participate in the message conversation")
  end

  it "enforces same-conversation authorship at the database boundary" do
    message = create(:message)
    membership = create(:conversation_membership)

    expect { message.update_columns(conversation_membership_id: membership.id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "bounds persisted text and sequence" do
    message = build(:message, body: "x" * 501, sequence: 0)

    expect(message).not_to be_valid
    expect(message.errors).to include(:body, :sequence)
  end

  it "exposes a deterministic chronological order" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)
    later = create(:message, conversation:, conversation_membership: membership, sequence: 2)
    earlier = create(:message, conversation:, conversation_membership: membership, sequence: 1)

    expect(conversation.messages.chronological).to eq([ earlier, later ])
  end

  it "advances the conversation activity timestamp after durable persistence" do
    conversation = create(:conversation, last_activity_at: 2.hours.ago)
    membership = create(:conversation_membership, conversation:)

    message = create(:message, conversation:, conversation_membership: membership)

    expect(conversation.reload.last_activity_at).to eq(message.created_at)
  end
end
