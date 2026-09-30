# spec/services/conversations/realtime_change_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::RealtimeChange do
  let(:conversation) { create(:conversation) }
  let(:membership) { create(:conversation_membership, conversation:) }

  it "increments a durable monotonic version and derives sequence/server markers" do
    create(:message, conversation:, conversation_membership: membership, sequence: 3)

    expect(described_class.record!(conversation:, kind: "message_created")).to eq(1)
    expect(described_class.record!(conversation:, kind: "read_state")).to eq(2)
    expect(conversation.reload.realtime_version).to eq(2)
    expect(described_class.snapshot(conversation:)).to include(
      conversationPublicId: conversation.public_id,
      kind: "snapshot",
      latestSequence: 3,
      version: 2
    )
  end

  it "rejects unsupported event kinds without changing durable state" do
    expect do
      described_class.record!(conversation:, kind: "presence")
    end.to raise_error(ArgumentError, "unsupported realtime change")
    expect(conversation.reload.realtime_version).to be_zero
  end

  it "versions create, edit, disposition, and withdrawal mutations while true no-ops stay quiet" do
    message = Conversations::CreateMessage.call(conversation:, membership:, body: "Initial")
    expect(conversation.reload.realtime_version).to eq(1)

    Conversations::EditMessage.call(message:, membership:, body: "Initial")
    expect(conversation.reload.realtime_version).to eq(1)

    Conversations::EditMessage.call(message:, membership:, body: "Edited")
    Conversations::SetDisposition.call(message:, membership:, kind: "like")
    Conversations::SetDisposition.call(message:, membership:, kind: "like")
    Conversations::WithdrawMessage.call(message:, membership:)

    expect(conversation.reload.realtime_version).to eq(4)
  end

  it "does not roll back a durable message when Cable broadcasting fails", database_cleaner: :truncation do
    allow(ConversationChannel).to receive(:broadcast_to).and_raise(IOError, "Cable unavailable")
    allow(Rails.logger).to receive(:warn)

    expect do
      Conversations::CreateMessage.call(conversation:, membership:, body: "Durable without Cable")
    end.to change(Message, :count).by(1)

    expect(conversation.reload.realtime_version).to eq(1)
    expect(conversation.messages.last.body).to eq("Durable without Cable")
    expect(Rails.logger).to have_received(:warn).with(/Conversation realtime broadcast failed: IOError/)
  end

  it "does not broadcast or retain a version from a rolled-back transaction", database_cleaner: :truncation do
    conversation
    allow(ConversationChannel).to receive(:broadcast_to)

    Conversation.transaction do
      described_class.record!(conversation:, kind: "read_state")
      raise ActiveRecord::Rollback
    end

    expect(conversation.reload.realtime_version).to be_zero
    expect(ConversationChannel).not_to have_received(:broadcast_to)
  end

  it "emits only a generic authorized invalidation envelope", database_cleaner: :truncation do
    envelopes = []
    allow(ConversationChannel).to receive(:broadcast_to) { |_conversation, envelope| envelopes << envelope }

    Conversations::CreateMessage.call(conversation:, membership:, body: "Private message body")

    expect(envelopes.sole).to include(
      conversationPublicId: conversation.public_id,
      kind: "message_created",
      latestSequence: 1,
      version: 1
    )
    expect(envelopes.sole.to_s).not_to include("Private message body", membership.key)
  end
end
