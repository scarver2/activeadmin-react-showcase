# spec/models/chat_participant_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatParticipant do
  it "scopes stable participant keys to a room" do
    participant = create(:chat_participant, key: "maya")

    expect(build(:chat_participant, chat_room: participant.chat_room, key: "maya")).not_to be_valid
    expect(build(:chat_participant, key: "maya")).to be_valid
  end

  it "requires a safe key and bounded display name" do
    participant = build(:chat_participant, key: "Maya Ortiz", display_name: "")

    expect(participant).not_to be_valid
    expect(participant.errors).to have_key(:key)
    expect(participant.errors).to have_key(:display_name)
  end

  it "preserves referential integrity while authored messages exist" do
    message = create(:chat_message)

    expect(message.author.destroy).to be(false)
    expect(message.author.errors[:base]).to include("Cannot delete record because dependent messages exist")
    expect { message.author.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
