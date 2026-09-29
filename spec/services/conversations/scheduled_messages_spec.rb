# spec/services/conversations/scheduled_messages_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation scheduled messages" do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.parse("2026-09-29 12:00:00") }
  let(:admin) { create(:admin_user) }
  let(:conversation) { create(:conversation) }
  let!(:membership) do
    create(:conversation_membership, admin_user: admin, conversation:, legacy_identity: false)
  end

  around do |example|
    travel_to(now) { example.run }
  end

  it "persists a future UTC instant and enqueues delivery for that instant" do
    scheduled_message = nil

    expect do
      scheduled_message = Conversations::ScheduleMessage.call(
        admin_user: admin,
        body: "  Release at noon ✅  ",
        conversation:,
        scheduled_for: 2.hours.from_now
      )
    end.to have_enqueued_job(DeliverScheduledMessageJob).with(kind_of(Integer)).at(2.hours.from_now)

    expect(scheduled_message).to have_attributes(
      body: "Release at noon ✅",
      scheduled_for: 2.hours.from_now,
      state: "pending"
    )
  end

  it "rejects a past instant and a non-member author" do
    expect do
      Conversations::ScheduleMessage.call(
        admin_user: admin,
        body: "Too late",
        conversation:,
        scheduled_for: 1.second.ago
      )
    end.to raise_error(ActiveRecord::RecordInvalid, /future/)

    expect do
      Conversations::ScheduleMessage.call(
        admin_user: create(:admin_user),
        body: "Forged",
        conversation:,
        scheduled_for: 1.hour.from_now
      )
    end.to raise_error(Conversations::ScheduleMessage::NotAuthorized)
  end

  it "delivers once when the job is retried" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 1.minute.ago
    )

    expect do
      2.times { Conversations::DeliverScheduledMessage.call(scheduled_message:, at: now) }
    end.to change(Message, :count).by(1)

    expect(scheduled_message.reload).to have_attributes(
      attempt_count: 1,
      delivered_at: now,
      state: "delivered"
    )
    expect(scheduled_message.delivered_message).to have_attributes(
      author: membership,
      body: scheduled_message.body,
      public_id: scheduled_message.delivery_public_id
    )
  end

  it "does nothing before the canonical delivery instant" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 1.minute.from_now
    )

    expect do
      Conversations::DeliverScheduledMessage.call(scheduled_message:, at: now)
    end.not_to change(Message, :count)
    expect(scheduled_message.reload).to have_attributes(attempt_count: 0, state: "pending")
  end

  it "fails closed when the author is no longer a member at execution time" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 1.minute.ago
    )
    membership.destroy!

    expect do
      Conversations::DeliverScheduledMessage.call(scheduled_message:, at: now)
    end.not_to change(Message, :count)
    expect(scheduled_message.reload).to have_attributes(
      attempt_count: 1,
      failed_at: now,
      failure_code: "membership_unavailable",
      state: "failed"
    )
  end

  it "records an unexpected delivery failure without exposing message content" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 1.minute.ago
    )
    allow(Conversations::CreateMessage).to receive(:call).and_raise(ActiveRecord::Deadlocked, "private payload")

    Conversations::DeliverScheduledMessage.call(scheduled_message:, at: now)

    expect(scheduled_message.reload).to have_attributes(
      attempt_count: 1,
      failure_code: "delivery_failed",
      failure_detail: "ActiveRecord::Deadlocked",
      state: "failed"
    )
  end

  it "reschedules failed work and cancels only manageable author-owned work" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      failed_at: now,
      failure_code: "delivery_failed",
      scheduled_for: 1.minute.ago,
      state: "failed"
    )

    expect do
      Conversations::UpdateScheduledMessage.call(
        admin_user: admin,
        body: "Second attempt",
        scheduled_for: 3.hours.from_now,
        scheduled_message:
      )
    end.to have_enqueued_job(DeliverScheduledMessageJob).with(scheduled_message.id).at(3.hours.from_now)
    expect(scheduled_message.reload).to have_attributes(
      body: "Second attempt",
      failed_at: nil,
      failure_code: nil,
      state: "pending"
    )

    Conversations::CancelScheduledMessage.call(admin_user: admin, scheduled_message:, at: now)
    expect(scheduled_message.reload).to have_attributes(cancelled_at: now, state: "cancelled")
    expect do
      Conversations::CancelScheduledMessage.call(admin_user: admin, scheduled_message:, at: now)
    end.to raise_error(Conversations::CancelScheduledMessage::NotCancellable)
  end
end
