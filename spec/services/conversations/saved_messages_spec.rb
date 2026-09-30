# spec/services/conversations/saved_messages_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::SavedMessages do
  let(:admin) { create(:admin_user) }
  let(:membership) { create(:conversation_membership, admin_user: admin) }
  let(:message) { create(:message, conversation: membership.conversation) }

  it "returns only the signed-in administrator's private, preloaded saved state" do
    mine = create(:saved_message, conversation: membership.conversation, membership:, message:)
    other_membership = create(:conversation_membership, conversation: membership.conversation)
    create(:saved_message, conversation: membership.conversation, membership: other_membership, message:)

    page = described_class.call(admin_user: admin)

    expect(page.records).to contain_exactly(mine)
    expect(page.records.sole.association(:membership)).to be_loaded
    expect(page.records.sole.association(:conversation)).to be_loaded
    expect(page.records.sole.association(:message)).to be_loaded
    expect(page.records.sole.message.association(:author)).to be_loaded
  end

  it "paginates stable created-at/id boundaries without omissions or duplicates" do
    stub_const("Conversations::SavedMessages::LIMIT", 2)
    timestamp = Time.zone.parse("2026-09-29 12:00:00")
    records = 5.times.map do |index|
      saved_message = create(
        :message,
        conversation: membership.conversation,
        sequence: index + 1
      )
      create(:saved_message, conversation: membership.conversation, membership:, message: saved_message, created_at: timestamp)
    end

    newest = described_class.call(admin_user: admin)
    middle = described_class.call(admin_user: admin, before: newest.older_cursor)
    oldest = described_class.call(admin_user: admin, before: middle.older_cursor)
    back_to_middle = described_class.call(admin_user: admin, after: oldest.newer_cursor)
    back_to_newest = described_class.call(admin_user: admin, after: middle.newer_cursor)

    expect(newest.records).to eq(records.reverse.first(2))
    expect(middle.records).to eq(records.reverse.drop(2).first(2))
    expect(oldest.records).to eq([ records.first ])
    expect(back_to_middle.records).to eq(middle.records)
    expect(back_to_newest.records).to eq(newest.records)
    expect(newest.newer_cursor).to be_nil
    expect(oldest.older_cursor).to be_nil
    expect([ newest, middle, oldest ].flat_map(&:records)).to match_array(records)
  end

  it "rejects ambiguous and malformed cursors" do
    expect { described_class.call(admin_user: admin, before: "bad", after: "also-bad") }
      .to raise_error(ArgumentError, "choose either before or after")
    expect { described_class.call(admin_user: admin, before: "not-a-cursor") }
      .to raise_error(ActiveRecord::RecordNotFound, "invalid saved-message cursor")
  end
end
