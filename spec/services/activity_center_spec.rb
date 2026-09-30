# spec/services/activity_center_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityCenter do
  include ActiveJob::TestHelper

  let(:admin_user) { create(:admin_user) }

  it "seeds deterministic activity idempotently" do
    first = ActivityCenter::Seed.call(admin_user:)
    second = ActivityCenter::Seed.call(admin_user:)
    expect(first.map { |item| item.params[:subject] }).to eq(second.map { |item| item.params[:subject] })
    expect(first.size).to eq(4)
    expect(first.unread.size).to eq(1)
  end

  it "persists through Noticed before best-effort Action Cable delivery" do
    notification = nil
    expect do
      perform_enqueued_jobs do
        notification = ActivityCenter::Create.call(
          admin_user:,
          attributes: {
            body: "Body",
            deep_link: "/admin/accounts",
            kind: "account",
            occurred_at: Time.current,
            subject: "Subject"
          }
        )
      end
    end.to have_broadcasted_to(ActivityCenterChannel.broadcasting_for(admin_user)).with(
      type: "notification", notification: hash_including(subject: "Subject")
    )
    expect(notification).to be_persisted
    expect(notification).to be_a(ActivityNotifier::Notification)
    expect(notification.event).to be_a(ActivityNotifier)
    expect(ActivityCenter::Serializer.new(notification).as_json).to include(subject: "Subject", read: false)
  end

  it "rejects unsupported kinds and non-local deep links" do
    attributes = {
      body: "Body",
      deep_link: "https://example.test/phishing",
      kind: "unsupported",
      occurred_at: Time.current,
      subject: "Subject"
    }

    expect { ActivityCenter::Create.call(admin_user:, attributes:) }
      .to raise_error(ActiveRecord::RecordInvalid, /unsupported activity kind|non-admin deep link/)
    expect(admin_user.notifications).to be_empty
  end

  it "changes Noticed read state durably and idempotently" do
    notification = ActivityCenter::Create.call(
      admin_user:,
      attributes: { body: "Body", deep_link: "/admin/accounts", kind: "account", occurred_at: Time.current, subject: "Subject" },
      enqueue_delivery: false
    )

    expect { ActivityCenter::SetReadState.call(notification:, read: true) }.to change(notification, :read_at).from(nil)
    expect { ActivityCenter::SetReadState.call(notification:, read: true) }.not_to change(notification.reload, :updated_at)
    expect { ActivityCenter::SetReadState.call(notification:, read: false) }.to change(notification, :read_at).to(nil)
    expect { ActivityCenter::SetReadState.call(notification:, read: false) }.not_to change(notification.reload, :updated_at)
  end

  it "builds and broadcasts the canonical unread projection" do
    first = ActivityCenter::Create.call(
      admin_user:,
      attributes: { body: "First", deep_link: "/admin/accounts", kind: "account", occurred_at: Time.current, subject: "First" },
      enqueue_delivery: false
    )
    second = ActivityCenter::Create.call(
      admin_user:,
      attributes: { body: "Second", deep_link: "/admin/accounts", kind: "account", occurred_at: Time.current, subject: "Second" },
      enqueue_delivery: false
    )
    second.mark_as_read!

    expect(ActivityCenter::UnreadProjection.envelope(admin_user)).to eq(
      type: "unread_count", unreadCount: 1, latestSequence: second.id
    )
    expect { ActivityCenter::UnreadProjection.broadcast(admin_user) }
      .to have_broadcasted_to(ActivityCenterChannel.broadcasting_for(admin_user))
      .with(type: "unread_count", unreadCount: 1, latestSequence: second.id)
    expect(first).to be_unread
  end
end
