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
    end.to have_enqueued_job(DeliverScheduledMessageJob).with(kind_of(Integer), 0).at(2.hours.from_now)

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

  it "fails authorization if membership disappears at the create or update lock boundary" do
    allow_any_instance_of(ConversationMembership).to receive(:lock!).and_raise(ActiveRecord::RecordNotFound)

    expect do
      Conversations::ScheduleMessage.call(
        admin_user: admin,
        body: "Raced create",
        conversation:,
        scheduled_for: 1.hour.from_now
      )
    end.to raise_error(Conversations::ScheduleMessage::NotAuthorized)
    expect(ScheduledMessage.count).to eq(0)

    allow_any_instance_of(ConversationMembership).to receive(:lock!).and_call_original
    scheduled_message = create(:scheduled_message, admin_user: admin, conversation:)
    allow_any_instance_of(ConversationMembership).to receive(:lock!).and_raise(ActiveRecord::RecordNotFound)

    expect do
      Conversations::UpdateScheduledMessage.call(
        admin_user: admin,
        body: "Raced update",
        scheduled_for: 2.hours.from_now,
        scheduled_message:
      )
    end.to raise_error(Conversations::UpdateScheduledMessage::NotManageable)
    expect(scheduled_message.reload.body).not_to eq("Raced update")
  end

  it "delivers once when the job is retried" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 1.minute.ago
    )

    expect do
      2.times do
        Conversations::DeliverScheduledMessage.call(
          scheduled_message:,
          expected_revision: scheduled_message.schedule_revision,
          at: now
        )
      end
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
      Conversations::DeliverScheduledMessage.call(
        scheduled_message:,
        expected_revision: scheduled_message.schedule_revision,
        at: now
      )
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
      Conversations::DeliverScheduledMessage.call(
        scheduled_message:,
        expected_revision: scheduled_message.schedule_revision,
        at: now
      )
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

    Conversations::DeliverScheduledMessage.call(
      scheduled_message:,
      expected_revision: scheduled_message.schedule_revision,
      at: now
    )

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
    end.to have_enqueued_job(DeliverScheduledMessageJob).with(scheduled_message.id, 1).at(3.hours.from_now)
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

  it "does not let a stale enqueue failure overwrite a reschedule or cancellation" do
    scheduled_message = create(:scheduled_message, admin_user: admin, conversation:)
    original_revision = scheduled_message.schedule_revision

    Conversations::UpdateScheduledMessage.call(
      admin_user: admin,
      body: "New generation",
      scheduled_for: 3.hours.from_now,
      scheduled_message:
    )
    Conversations::ScheduleMessage.send(
      :mark_enqueue_failure,
      scheduled_message,
      "stale reschedule failure",
      expected_revision: original_revision
    )
    expect(scheduled_message.reload).to have_attributes(state: "pending", schedule_revision: 1)

    revision_before_cancel = scheduled_message.schedule_revision
    Conversations::CancelScheduledMessage.call(admin_user: admin, scheduled_message:, at: now)
    Conversations::ScheduleMessage.send(
      :mark_enqueue_failure,
      scheduled_message,
      "stale cancellation failure",
      expected_revision: revision_before_cancel
    )
    expect(scheduled_message.reload).to have_attributes(state: "cancelled", schedule_revision: 2)
  end

  it "does not let a stale delivery failure overwrite delivered or newly rescheduled work" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 1.minute.ago
    )
    original_revision = scheduled_message.schedule_revision
    Conversations::DeliverScheduledMessage.call(
      scheduled_message:,
      expected_revision: original_revision,
      at: now
    )
    Conversations::DeliverScheduledMessage.send(
      :record_failure,
      scheduled_message,
      ActiveRecord::Deadlocked.new("stale"),
      at: now,
      expected_revision: original_revision
    )
    expect(scheduled_message.reload.state).to eq("delivered")

    retryable = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      failed_at: now,
      failure_code: "delivery_failed",
      scheduled_for: 1.minute.ago,
      state: "failed"
    )
    failed_revision = retryable.schedule_revision
    Conversations::UpdateScheduledMessage.call(
      admin_user: admin,
      body: "Fresh retry",
      scheduled_for: 4.hours.from_now,
      scheduled_message: retryable
    )
    Conversations::DeliverScheduledMessage.send(
      :record_failure,
      retryable,
      ActiveRecord::Deadlocked.new("stale"),
      at: now,
      expected_revision: failed_revision
    )
    expect(retryable.reload).to have_attributes(state: "pending", schedule_revision: 1)
  end

  it "makes an old generation job a no-op after a newer generation becomes due" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      body: "Old generation",
      conversation:,
      scheduled_for: 30.minutes.ago
    )
    old_revision = scheduled_message.schedule_revision
    Conversations::UpdateScheduledMessage.call(
      admin_user: admin,
      at: 2.hours.ago,
      body: "New generation",
      scheduled_for: 1.hour.ago,
      scheduled_message:
    )

    expect do
      Conversations::DeliverScheduledMessage.call(
        scheduled_message:,
        expected_revision: old_revision,
        at: now
      )
    end.not_to change(Message, :count)
    expect(scheduled_message.reload).to have_attributes(attempt_count: 0, state: "pending")

    expect do
      Conversations::DeliverScheduledMessage.call(
        scheduled_message:,
        expected_revision: scheduled_message.schedule_revision,
        at: now
      )
    end.to change(Message, :count).by(1)
    expect(scheduled_message.reload.delivered_message.body).to eq("New generation")
  end

  it "does not let an old generation job deliver a newer generation whose enqueue failed" do
    scheduled_message = create(
      :scheduled_message,
      admin_user: admin,
      conversation:,
      scheduled_for: 30.minutes.ago
    )
    old_revision = scheduled_message.schedule_revision
    Conversations::UpdateScheduledMessage.call(
      admin_user: admin,
      at: 2.hours.ago,
      body: "New generation that failed enqueue",
      scheduled_for: 1.hour.ago,
      scheduled_message:
    )
    Conversations::ScheduleMessage.send(
      :mark_enqueue_failure,
      scheduled_message,
      "new generation enqueue failure",
      expected_revision: scheduled_message.schedule_revision
    )

    expect do
      Conversations::DeliverScheduledMessage.call(
        scheduled_message:,
        expected_revision: old_revision,
        at: now
      )
    end.not_to change(Message, :count)
    expect(scheduled_message.reload).to have_attributes(attempt_count: 0, state: "failed")
  end
end
