# spec/models/saved_message_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SavedMessage do
  it "belongs to one membership and message in the same conversation" do
    saved_message = build(:saved_message)

    expect(saved_message).to be_valid
  end

  it "rejects a membership or message from another conversation" do
    saved_message = build(:saved_message, membership: create(:conversation_membership))

    expect(saved_message).not_to be_valid
    expect(saved_message.errors[:base]).to include("membership and message must belong to the saved conversation")
  end

  it "allows each member to save a message once" do
    saved_message = create(:saved_message)

    duplicate = build(
      :saved_message,
      conversation: saved_message.conversation,
      membership: saved_message.membership,
      message: saved_message.message
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:message_id]).to be_present
  end

  it "removes private state rather than retaining content when its message is deleted" do
    saved_message = create(:saved_message)

    saved_message.message.delete

    expect(described_class.where(id: saved_message.id)).to be_empty
  end
end
