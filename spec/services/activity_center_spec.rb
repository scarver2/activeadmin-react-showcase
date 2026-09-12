# spec/services/activity_center_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityCenter do
  let(:admin_user) { create(:admin_user) }

  it "seeds deterministic activity idempotently" do
    first = ActivityCenter::Seed.call(admin_user:)
    second = ActivityCenter::Seed.call(admin_user:)
    expect(first.pluck(:subject)).to eq(second.pluck(:subject))
    expect(first.size).to eq(4)
    expect(first.unread.size).to eq(1)
  end

  it "persists before broadcasting a serialized notification" do
    allow(ActionCable.server).to receive(:broadcast) do |_stream, payload|
      expect(ActivityNotification.exists?(payload.dig(:notification, :id))).to be(true)
    end
    notification = ActivityCenter::Create.call(
      admin_user:,
      attributes: { body: "Body", deep_link: "/admin/accounts", kind: "account", occurred_at: Time.current, subject: "Subject" }
    )
    expect(ActionCable.server).to have_received(:broadcast).with(
      ActivityCenter::Create.channel_for(admin_user), hash_including(type: "notification")
    )
    expect(ActivityCenter::Serializer.new(notification).as_json).to include(subject: "Subject", read: false, sequence: 1)
  end
end
