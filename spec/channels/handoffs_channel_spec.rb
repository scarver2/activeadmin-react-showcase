# spec/channels/handoffs_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe HandoffsChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }

  before { stub_connection current_admin_user: admin_user }

  it "streams only the owning human's work hints" do
    item = admin_user.handoff_items.create!(title: "Synthetic checklist")
    subscribe(item_id: item.public_id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(item.broadcast_key)
  end

  it "rejects another owner's item" do
    item = create(:admin_user).handoff_items.create!(title: "Synthetic checklist")
    subscribe(item_id: item.public_id)
    expect(subscription).to be_rejected
  end
end
