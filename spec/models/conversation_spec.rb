# spec/models/conversation_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation do
  it "assigns a stable unique public identity on creation" do
    conversation = create(:conversation, public_id: nil)

    expect(conversation.public_id).to match(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/)
    expect(conversation.reload.public_id).to eq(conversation.public_id)
  end

  describe ".by_recent_activity" do
    it "orders conversations by canonical activity and then stable identity" do
      older = create(:conversation, last_activity_at: 2.hours.ago)
      newer = create(:conversation, last_activity_at: 1.hour.ago)

      expect(described_class.by_recent_activity).to eq([ newer, older ])
    end
  end

  describe "membership authority" do
    it "resolves only memberships linked to the authenticated administrator" do
      user = create(:admin_user)
      conversation = create(:conversation)
      membership = create(:conversation_membership, conversation:, admin_user: user)

      expect(conversation).to be_member(user)
      expect(conversation.membership_for(user)).to eq(membership)
      expect(conversation).not_to be_member(create(:admin_user))
      expect(conversation).not_to be_member(nil)
    end
  end

  it "bounds the title and optional topic" do
    conversation = build(:conversation, title: "", topic: "x" * 161)

    expect(conversation).not_to be_valid
    expect(conversation.errors).to include(:title, :topic)
  end
end
