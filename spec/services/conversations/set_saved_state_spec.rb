# spec/services/conversations/set_saved_state_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::SetSavedState do
  let(:conversation) { create(:conversation) }
  let(:membership) { create(:conversation_membership, conversation:) }
  let(:message) { create(:message, conversation:) }

  it "saves and removes private state idempotently without changing the message" do
    original_attributes = message.attributes

    first = nil
    expect { first = described_class.call(message:, membership:, saved: true) }
      .not_to change(Noticed::Notification, :count)
    replay = described_class.call(message:, membership:, saved: true)

    expect(replay).to eq(first)
    expect(membership.saved_messages.reload).to contain_exactly(first)
    expect(message.reload.attributes).to eq(original_attributes)

    expect { described_class.call(message:, membership:, saved: false) }
      .to change { membership.saved_messages.reload.count }.from(1).to(0)
    expect { described_class.call(message:, membership:, saved: false) }
      .not_to(change { membership.saved_messages.reload.count })
  end

  it "rechecks same-conversation membership authority before every mutation" do
    outsider = create(:conversation_membership)

    expect { described_class.call(message:, membership: outsider, saved: true) }
      .to raise_error(described_class::NotAuthorized)
    expect(message.saved_messages).to be_empty
  end

  it "rejects a stale membership that no longer exists" do
    stale_membership = membership
    stale_membership.delete

    expect { described_class.call(message:, membership: stale_membership, saved: true) }
      .to raise_error(described_class::NotAuthorized)
  end

  it "requires an explicit boolean state" do
    expect { described_class.call(message:, membership:, saved: nil) }
      .to raise_error(ArgumentError, "saved must be boolean")
  end

  it "retries bounded SQLite busy contention" do
    saved_message = create(:saved_message, conversation:, membership:, message:)
    attempts = 0
    allow(described_class).to receive(:sleep)
    allow(described_class).to receive(:apply) do
      attempts += 1
      raise ActiveRecord::StatementInvalid.new("busy"), cause: SQLite3::BusyException.new if attempts == 1

      saved_message
    end

    expect(described_class.call(message:, membership:, saved: true)).to eq(saved_message)
    expect(described_class).to have_received(:sleep).with(0.01)
  end

  it "reconciles a unique-insert race to its canonical saved row" do
    saved_message = create(:saved_message, conversation:, membership:, message:)
    allow(described_class).to receive(:apply).and_raise(ActiveRecord::RecordNotUnique)

    expect(described_class.call(message:, membership:, saved: true)).to eq(saved_message)
    expect { described_class.call(message:, membership:, saved: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "converges concurrent duplicate saves on the unique private row", database_cleaner: :truncation do
    results = run_concurrently(true, true)

    expect(results).to all(be_a(SavedMessage))
    expect(SavedMessage.where(membership_id: membership.id, message_id: message.id).count).to eq(1)
  end

  it "keeps opposite concurrent requests bounded and retryable to canonical desired state", database_cleaner: :truncation do
    results = run_concurrently(true, false)

    expect(results).to all(satisfy { |result| result.nil? || result.is_a?(SavedMessage) })
    expect(SavedMessage.where(membership_id: membership.id, message_id: message.id).count).to be_between(0, 1)

    described_class.call(message:, membership:, saved: false)
    expect(membership.saved_messages.reload).to be_empty
    described_class.call(message:, membership:, saved: true)
    expect(membership.saved_messages.reload.sole.message).to eq(message)
  end

  def run_concurrently(*states)
    ready = Queue.new
    start = Queue.new
    threads = states.map do |saved|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          thread_membership = ConversationMembership.find(membership.id)
          thread_message = Message.find(message.id)
          ready << true
          start.pop
          described_class.call(message: thread_message, membership: thread_membership, saved:)
        end
      rescue StandardError => error
        error
      end
    end
    states.size.times { ready.pop }
    states.size.times { start << true }
    threads.map(&:value)
  end
end
