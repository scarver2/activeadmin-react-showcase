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
      .not_to change(ActivityNotification, :count)
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
end
