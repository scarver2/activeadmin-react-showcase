# spec/services/conversations/create_message_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::CreateMessage, database_cleaner: :truncation do
  def concurrently(count, &block)
    ready = Queue.new
    start = Queue.new
    threads = count.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          block.call
        end
      end
    end
    count.times { ready.pop }
    count.times { start << true }
    threads.map(&:value)
  end

  it "allocates monotonic per-conversation sequences under the conversation lock" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)

    messages = 3.times.map do |index|
      described_class.call(conversation:, membership:, body: "Message #{index + 1}")
    end

    expect(messages.map(&:sequence)).to eq([ 1, 2, 3 ])
    expect(conversation.messages.chronological).to eq(messages)
  end

  it "serializes concurrent allocations into one gapless durable order" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)

    message_ids = concurrently(4) do
      described_class.call(
        conversation: Conversation.find(conversation.id),
        membership: ConversationMembership.find(membership.id),
        body: "Concurrent message"
      ).id
    end

    expect(message_ids.uniq.size).to eq(4)
    expect(conversation.messages.chronological.pluck(:sequence)).to eq([ 1, 2, 3, 4 ])
  end

  it "rejects a membership from another conversation before persistence" do
    conversation = create(:conversation)
    membership = create(:conversation_membership)

    expect { described_class.call(conversation:, membership:, body: "Forged actor") }
      .to raise_error(ActiveRecord::RecordInvalid)
    expect(conversation.messages).to be_empty
  end

  it "normalizes surrounding whitespace while preserving multiline content" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)

    message = described_class.call(conversation:, membership:, body: "  First line\nSecond line  ")

    expect(message.body).to eq("First line\nSecond line")
  end
end
