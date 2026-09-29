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

  it "rolls back an attempted insert before retrying a busy activity write" do
    conversation = create(:conversation, last_activity_at: 2.hours.ago)
    membership = create(:conversation_membership, conversation:)
    busy = ActiveRecord::StatementInvalid.new("database is busy")
    attempts = 0

    allow(described_class).to receive(:sqlite_busy?).with(busy).and_return(true)
    allow(conversation).to receive(:update!).and_wrap_original do |method, *arguments|
      attempts += 1
      raise busy if attempts == 1

      method.call(*arguments)
    end

    message = described_class.call(conversation:, membership:, body: "Retry safely")

    expect(message).to be_persisted
    expect(conversation.messages.reload.pluck(:sequence)).to eq([ 1 ])
  end

  it "rejects a membership from another conversation before persistence" do
    conversation = create(:conversation)
    membership = create(:conversation_membership)

    expect { described_class.call(conversation:, membership:, body: "Forged actor") }
      .to raise_error(Conversations::CreateMessage::NotAuthorized)
    expect(conversation.messages).to be_empty
  end

  it "normalizes surrounding whitespace while preserving multiline content" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)

    message = described_class.call(conversation:, membership:, body: "  First line\nSecond line  ")

    expect(message.body).to eq("First line\nSecond line")
  end

  it "replays an ordinary client-identified send without creating another message" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)
    mentioned = create(:conversation_membership, conversation:)
    original = create(:message, conversation:, conversation_membership: mentioned, sequence: 1)
    arguments = {
      body: "  Replay-safe @#{mentioned.display_name}  ",
      conversation:,
      membership:,
      mentioned_memberships: [ mentioned ],
      public_id: "5b943ade-232d-426d-bfac-b8c7a840aff8",
      reply_to: original
    }

    first = described_class.call(**arguments)
    replay = described_class.call(**arguments)

    expect(replay).to eq(first)
    expect(conversation.messages.where(public_id: arguments.fetch(:public_id)).count).to eq(1)
    expect(conversation.messages.order(:sequence).pluck(:sequence)).to eq([ 1, 2 ])
  end

  it "rejects reuse of a send identity with different content or authority" do
    conversation = create(:conversation)
    membership = create(:conversation_membership, conversation:)
    public_id = "fa8f976c-cbbc-4c1d-83af-176df22b7cec"
    described_class.call(conversation:, membership:, body: "Original", public_id:)

    expect { described_class.call(conversation:, membership:, body: "Changed", public_id:) }
      .to raise_error(Conversations::CreateMessage::ReplayConflict)
    expect do
      described_class.call(
        conversation: create(:conversation),
        membership: create(:conversation_membership),
        body: "Original",
        public_id:
      )
    end.to raise_error(Conversations::CreateMessage::NotAuthorized)
  end
end
