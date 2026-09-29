# spec/services/conversations/set_read_state_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::SetReadState do
  let(:conversation) { create(:conversation) }
  let(:membership) { create(:conversation_membership, conversation:) }
  let(:other_membership) { create(:conversation_membership, conversation:) }
  let!(:first) { create(:message, conversation:, conversation_membership: other_membership, sequence: 1) }
  let!(:second) { create(:message, conversation:, conversation_membership: other_membership, sequence: 2) }

  it "versions effective read and unread changes in the same durable transaction" do
    expect do
      described_class.call(membership:, message: second, state: :read_through)
    end.to change { membership.reload.last_read_message }.from(nil).to(second)
      .and change { conversation.reload.realtime_version }.from(0).to(1)

    expect do
      described_class.call(membership:, message: second, state: :unread_from)
    end.to change { membership.reload.last_read_message }.from(second).to(first)
      .and change { conversation.reload.realtime_version }.from(1).to(2)
  end

  it "keeps true no-ops quiet" do
    described_class.call(membership:, message: second, state: :read_through)
    version = conversation.reload.realtime_version

    expect do
      described_class.call(membership:, message: second, state: :read_through)
    end.not_to change { conversation.reload.realtime_version }.from(version)

    described_class.call(membership:, message: second, state: :unread_from)
    unread_version = conversation.reload.realtime_version
    expect do
      described_class.call(membership:, message: second, state: :unread_from)
    end.not_to change { conversation.reload.realtime_version }.from(unread_version)
  end

  it "rejects unsupported states before changing durable state" do
    expect do
      described_class.call(membership:, message: second, state: :presence)
    end.to raise_error(ArgumentError, "unsupported read state")

    expect(membership.reload.last_read_message).to be_nil
    expect(conversation.reload.realtime_version).to be_zero
  end

  it "rolls the read cursor back when realtime versioning fails" do
    allow(Conversations::RealtimeChange).to receive(:record!).and_raise(ActiveRecord::StatementInvalid, "failed")

    expect do
      described_class.call(membership:, message: second, state: :read_through)
    end.to raise_error(ActiveRecord::StatementInvalid, "failed")

    expect(membership.reload.last_read_message).to be_nil
  end
end
