# spec/services/conversations/saved_messages_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::SavedMessages do
  let(:admin) { create(:admin_user) }
  let(:membership) { create(:conversation_membership, admin_user: admin) }
  let(:message) { create(:message, conversation: membership.conversation) }

  it "returns only the signed-in administrator's private saved state" do
    mine = create(:saved_message, conversation: membership.conversation, membership:, message:)
    other_membership = create(:conversation_membership, conversation: membership.conversation)
    create(:saved_message, conversation: membership.conversation, membership: other_membership, message:)

    expect(described_class.call(admin_user: admin)).to contain_exactly(mine)
  end

  it "orders newest saved state first and caps the result" do
    older = create(:saved_message, conversation: membership.conversation, membership:, message:, created_at: 1.day.ago)
    newer_message = create(
      :message,
      conversation: membership.conversation,
      sequence: membership.conversation.messages.maximum(:sequence) + 1
    )
    newer = create(:saved_message, conversation: membership.conversation, membership:, message: newer_message)

    expect(described_class.call(admin_user: admin)).to eq([ newer, older ])
  end
end
