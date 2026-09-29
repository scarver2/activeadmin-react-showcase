# spec/models/conversation_membership_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConversationMembership do
  def concurrently(count, &block)
    ready = Queue.new
    start = Queue.new
    threads = count.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          block.call(index)
        end
      end
    end
    count.times { ready.pop }
    count.times { start << true }
    threads.map(&:value)
  end

  it "permits one membership per authenticated user and conversation" do
    membership = create(:conversation_membership)

    duplicate = build(
      :conversation_membership,
      admin_user: membership.admin_user,
      conversation: membership.conversation
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors).to have_key(:admin_user_id)
  end

  it "requires new durable memberships to belong to an authenticated administrator" do
    membership = build(:conversation_membership, admin_user: nil, key: "maya")

    expect(membership).not_to be_valid
    expect(membership.errors).to have_key(:admin_user)
  end

  it "preserves only explicitly marked unlinked identities from the precursor" do
    membership = build(:conversation_membership, :legacy, key: "maya")

    expect(membership).to be_valid
    expect(build(:conversation_membership, :legacy, admin_user: create(:admin_user))).not_to be_valid
  end

  it "enforces explicit identity authority at the database boundary" do
    membership = create(:conversation_membership, :legacy)

    expect { membership.update_columns(legacy_identity: false) }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it "tracks a monotonic per-member read cursor and unread count" do
    membership = create(:conversation_membership)
    first = create(:message, conversation: membership.conversation, conversation_membership: membership, sequence: 1)
    second = create(:message, conversation: membership.conversation, conversation_membership: membership, sequence: 2)

    expect { membership.mark_read_through!(first) }.to change(membership, :unread_count).from(2).to(1)
    expect { membership.mark_read_through!(second) }.to change(membership, :unread_count).from(1).to(0)

    membership.mark_read_through!(first)

    expect(membership.reload.last_read_message).to eq(second)
    expect(membership.last_read_at).to be_present
  end

  it "does not let a stale membership instance regress the read cursor" do
    membership = create(:conversation_membership)
    first = create(:message, conversation: membership.conversation, conversation_membership: membership, sequence: 1)
    second = create(:message, conversation: membership.conversation, conversation_membership: membership, sequence: 2)
    stale = described_class.find(membership.id)

    membership.mark_read_through!(second)
    stale.mark_read_through!(first)

    expect(membership.reload.last_read_message).to eq(second)
  end

  it "serializes concurrent read advancement monotonically", database_cleaner: :truncation do
    membership = create(:conversation_membership)
    messages = 4.times.map do |index|
      create(:message, conversation: membership.conversation, conversation_membership: membership, sequence: index + 1)
    end

    concurrently(2) do |index|
      cursor = described_class.find(membership.id)
      target = Message.find([ messages.second.id, messages.last.id ].fetch(index))
      cursor.mark_read_through!(target)
    end

    expect(membership.reload.last_read_message).to eq(messages.last)
  end

  it "can deliberately mark the whole conversation unread" do
    membership = create(:conversation_membership)
    message = create(:message, conversation: membership.conversation, conversation_membership: membership)
    membership.mark_read_through!(message)

    membership.mark_unread!

    expect(membership).to have_attributes(last_read_message: nil, last_read_at: nil)
    expect(membership.unread_count).to eq(1)
  end

  it "rejects a read cursor from another conversation" do
    membership = create(:conversation_membership)
    message = create(:message)

    expect { membership.mark_read_through!(message) }
      .to raise_error(ArgumentError, "message must belong to the membership conversation")
  end

  it "enforces the same-conversation read cursor at the database boundary" do
    membership = create(:conversation_membership)
    message = create(:message)

    expect { membership.update_columns(last_read_message_id: message.id) }
      .to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
