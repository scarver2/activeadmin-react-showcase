# spec/services/conversations/inbox_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::Inbox do
  it "returns a bounded recent inbox with projected unread counts and no history preload" do
    admin = create(:admin_user)
    older = create(:conversation, last_activity_at: 2.hours.ago)
    newer = create(:conversation, last_activity_at: 1.hour.ago)
    older_membership = create(:conversation_membership, admin_user: admin, conversation: older)
    newer_membership = create(:conversation_membership, admin_user: admin, conversation: newer)
    read = create(:message, conversation: newer, conversation_membership: newer_membership, sequence: 1)
    create(:message, conversation: newer, conversation_membership: newer_membership, sequence: 2)
    newer_membership.mark_read_through!(read)

    queries = []
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      queries << payload[:sql] if payload[:name] != "SCHEMA" && payload[:sql].start_with?("SELECT")
    end
    entries = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      described_class.call(admin_user: admin)
    end

    expect(entries.map { |entry| entry.membership }).to eq([ newer_membership, older_membership ])
    expect(entries.map(&:unread_count)).to eq([ 1, 0 ])
    expect(entries).to all(satisfy { |entry| !entry.membership.conversation.association(:messages).loaded? })
    expect(queries.length).to be <= 4
  end
end
