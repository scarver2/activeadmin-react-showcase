# spec/models/message_signals_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation message signal constraints" do
  let(:conversation) { create(:conversation) }
  let(:author) { create(:conversation_membership, conversation:) }
  let(:message) { create(:message, conversation:, conversation_membership: author) }

  it "accepts a reply within the same conversation" do
    reply = build(
      :message,
      conversation:,
      conversation_membership: author,
      reply_to_message: message,
      sequence: message.sequence + 1
    )

    expect(reply).to be_valid
  end

  it "rejects cross-conversation replies in Rails and at the database boundary" do
    other_message = create(:message)
    reply = build(
      :message,
      conversation:,
      conversation_membership: author,
      reply_to_message: other_message,
      sequence: 2
    )

    expect(reply).not_to be_valid
    persisted_reply = create(:message, conversation:, conversation_membership: author, sequence: 2)
    expect { persisted_reply.update_columns(reply_to_message_id: other_message.id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "enforces one disposition per membership and message" do
    membership = create(:conversation_membership, conversation:)
    create(:message_disposition, message:, membership:)

    duplicate = build(:message_disposition, message:, membership:, kind: "question")

    expect(duplicate).not_to be_valid
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "enforces disposition membership authority at the database boundary" do
    disposition = create(:message_disposition, message:)
    outsider = create(:conversation_membership)

    expect { disposition.update_columns(membership_id: outsider.id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "enforces durable mentioned membership authority at the database boundary" do
    mention = create(:message_mention, message:)
    outsider = create(:conversation_membership)

    expect { mention.update_columns(mentioned_membership_id: outsider.id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
