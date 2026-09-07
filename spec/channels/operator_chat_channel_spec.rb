# spec/channels/operator_chat_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperatorChatChannel, type: :channel do
  let(:room) { OperatorChat::Seed.call }

  it "rejects missing room and unauthenticated connections" do
    stub_connection current_admin_user: nil
    subscribe(room_id: room.public_id)
    expect(subscription).to be_rejected

    stub_connection current_admin_user: create(:admin_user)
    subscribe(room_id: "missing")
    expect(subscription).to be_rejected
  end

  it "authorizes, streams, and replays messages after a valid cursor" do
    stub_connection current_admin_user: create(:admin_user)
    subscribe(room_id: room.public_id, after_sequence: 1)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(room.broadcast_key)
    expect(transmissions.pluck("message").pluck("sequence")).to eq([ 2 ])
  end

  it "rejects malformed and negative replay cursors" do
    stub_connection current_admin_user: create(:admin_user)

    subscribe(room_id: room.public_id, after_sequence: "invalid")
    expect(subscription).to be_rejected

    subscribe(room_id: room.public_id, after_sequence: -1)
    expect(subscription).to be_rejected
  end
end
