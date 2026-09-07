# spec/services/operator_chat_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Operator chat services" do
  it "seeds a deterministic room and does not duplicate messages" do
    room = OperatorChat::Seed.call
    OperatorChat::Seed.call

    expect(room.messages.order(:sequence).pluck(:author_key, :sequence)).to eq([ [ "maya", 1 ], [ "jordan", 2 ] ])
  end

  it "persists a bounded operator-authored message before broadcasting it" do
    room = create(:chat_room)
    allow(ActionCable.server).to receive(:broadcast)

    message = OperatorChat::PostMessage.call(room:, body: "  Please proceed.  ")

    expect(message).to have_attributes(author_key: "operator", author_name: "You", body: "Please proceed.", sequence: 1)
    expect(ActionCable.server).to have_received(:broadcast).with(room.broadcast_key, hash_including(type: "message"))
  end

  it "rejects blank and oversized messages" do
    room = create(:chat_room)

    expect { OperatorChat::PostMessage.call(room:, body: " ") }.to raise_error(ActiveRecord::RecordInvalid)
    expect { OperatorChat::PostMessage.call(room:, body: "x" * 501) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "restores the safe synthetic conversation and broadcasts a snapshot" do
    room = create(:chat_room)
    create(:chat_message, chat_room: room, author_key: "operator", author_name: "You", body: "Temporary", sequence: 1)
    allow(ActionCable.server).to receive(:broadcast)

    messages = OperatorChat::Reset.call(room:)

    expect(messages.pluck(:author_key)).to eq(%w[maya jordan])
    expect(ActionCable.server).to have_received(:broadcast).with(room.broadcast_key, hash_including(type: "reset"))
  end
end
