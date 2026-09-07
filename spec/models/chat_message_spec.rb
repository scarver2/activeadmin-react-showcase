# spec/models/chat_message_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatMessage do
  it "requires the persisted author to participate in the same room" do
    message = build(:chat_message, author: create(:chat_participant))

    expect(message).not_to be_valid
    expect(message.errors[:author]).to include("must participate in the message room")
  end

  it "accepts a persisted author from the message room" do
    expect(build(:chat_message)).to be_valid
  end
end
