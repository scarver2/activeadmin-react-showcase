# spec/channels/activity_center_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityCenterChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }

  it "rejects unauthenticated subscriptions" do
    stub_connection current_admin_user: nil
    subscribe
    expect(subscription).to be_rejected
  end

  it "streams the owner channel and replays after a cursor" do
    ActivityCenter::Seed.call(admin_user:)
    stub_connection current_admin_user: admin_user
    subscribe(after_sequence: 2)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(ActivityCenter::Create.channel_for(admin_user))
    expect(transmissions.pluck("notification").pluck("sequence")).to eq([ 3, 4 ])
  end

  it "rejects invalid replay cursors" do
    stub_connection current_admin_user: admin_user
    subscribe(after_sequence: "bad")
    expect(subscription).to be_rejected
  end
end
