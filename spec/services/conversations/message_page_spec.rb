# spec/services/conversations/message_page_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::MessagePage do
  let(:conversation) { create(:conversation) }
  let(:membership) { create(:conversation_membership, conversation:) }

  it "returns the newest 50 in chronological order with a positive older cursor" do
    55.times do |index|
      create(:message, conversation:, conversation_membership: membership, sequence: index + 1)
    end

    page = described_class.call(conversation:)

    expect(page.messages.map(&:sequence)).to eq((6..55).to_a)
    expect(page.older_cursor).to eq(6)
    older_page = described_class.call(conversation:, before: page.older_cursor)
    expect(older_page.messages.map(&:sequence)).to eq((1..5).to_a)
  end

  it "rejects non-positive and malformed cursors" do
    expect { described_class.call(conversation:, before: "0") }.to raise_error(ActionController::BadRequest)
    expect { described_class.call(conversation:, before: "oops") }.to raise_error(ActionController::BadRequest)
  end
end
