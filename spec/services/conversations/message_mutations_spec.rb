# spec/services/conversations/message_mutations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation message mutations" do
  let(:conversation) { create(:conversation) }
  let(:membership) { create(:conversation_membership, conversation:) }
  let(:other_membership) { create(:conversation_membership, conversation:) }
  let(:message) { create(:message, conversation:, conversation_membership: membership, created_at: 5.minutes.ago) }

  it "edits an author's message within 15 minutes" do
    described = Conversations::EditMessage.call(message:, membership:, body: "  Revised ✅\nsecond line  ")

    expect(described).to have_attributes(body: "Revised ✅\nsecond line", edited_at: be_present)
  end

  it "does not touch timestamps for an unchanged normalized edit" do
    original_updated_at = message.updated_at

    expect do
      Conversations::EditMessage.call(message:, membership:, body: "  #{message.body}  ")
    end.not_to(change { message.reload.updated_at })
    expect(message.edited_at).to be_nil
    expect(message.updated_at).to eq(original_updated_at)
  end

  it "rejects edits by another member and after the edit window" do
    expect do
      Conversations::EditMessage.call(message:, membership: other_membership, body: "No")
    end.to raise_error(Conversations::EditMessage::EditWindowClosed)

    message.update_column(:created_at, 16.minutes.ago)
    expect do
      Conversations::EditMessage.call(message:, membership:, body: "Too late")
    end.to raise_error(Conversations::EditMessage::EditWindowClosed)
  end

  it "includes the exact 15-minute boundary" do
    boundary = message.reload.created_at + Message::EDIT_WINDOW

    expect do
      Conversations::EditMessage.call(message:, membership:, body: "At the boundary", at: boundary)
    end.not_to raise_error
  end

  it "persists a fixed tombstone and permits an idempotent author retry after cutoff" do
    Conversations::WithdrawMessage.call(message:, membership:)
    message.update_column(:created_at, 1.hour.ago)

    expect { Conversations::WithdrawMessage.call(message:, membership:) }.not_to raise_error
    expect(message.reload).to have_attributes(body: Message::WITHDRAWN_BODY, withdrawn_at: be_present)
  end

  it "does not reveal another author's withdrawn-message state" do
    Conversations::WithdrawMessage.call(message:, membership:)

    expect do
      Conversations::WithdrawMessage.call(message:, membership: other_membership)
    end.to raise_error(Conversations::WithdrawMessage::WithdrawalNotAllowed)
  end
end
