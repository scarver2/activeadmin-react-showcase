# spec/services/conversations/seed_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::Seed do
  it "uses only the supplied authenticated administrator" do
    admin = create(:admin_user)

    expect { described_class.call(admin_user: admin) }.not_to change(AdminUser, :count)
    conversation = Conversation.find_by!(public_id: described_class::CONVERSATION_ID)
    expect(conversation.memberships.pluck(:admin_user_id)).to contain_exactly(admin.id, nil)
    expect(conversation.messages.count).to eq(3)
    expect(conversation.scheduled_messages.pluck(:state)).to contain_exactly("delivered", "pending")
    expect(conversation.memberships.find_by!(admin_user: admin).saved_messages.count).to eq(1)
    expect(conversation.memberships.find_by!(key: "release-lead").saved_messages).to be_empty
  end

  it "has no side effects while the rollout gate is disabled" do
    admin = create(:admin_user)
    counts = [ Conversation.count, ConversationMembership.count, Message.count, SavedMessage.count, ScheduledMessage.count ]

    ClimateControl.modify(SHOWCASE_CONVERSATIONS_ENABLED: "false") do
      expect { described_class.call(admin_user: admin) }.to raise_error(Conversations::Seed::Disabled)
      expect([ Conversation.count, ConversationMembership.count, Message.count, SavedMessage.count, ScheduledMessage.count ])
        .to eq(counts)
    end
  end
end
