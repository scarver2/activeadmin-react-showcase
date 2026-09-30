# spec/services/activity_center/actionable_inbox_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Actionable activity inbox" do
  let(:admin_user) { create(:admin_user) }
  let(:now) { Time.zone.parse("2026-09-30 10:00:00") }

  def create_notification(attention_kind: "fyi", priority: "normal", record: nil)
    ActivityCenter::Create.call(
      admin_user:,
      attention_kind:,
      attributes: {
        body: "A durable notification",
        deep_link: "/admin/kanban_workflow",
        kind: "operation",
        occurred_at: now,
        subject: "Review requested"
      },
      enqueue_delivery: false,
      priority:,
      record:
    )
  end

  it "filters recipient state and excludes dismissed or currently snoozed items from the count" do
    active = create_notification(attention_kind: "requires_action", priority: "high")
    snoozed = create_notification
    dismissed = create_notification
    read = create_notification
    snoozed.update!(snoozed_until: now + 30.minutes)
    dismissed.update!(dismissed_at: now)
    read.mark_as_read!

    inbox = ActivityCenter::Inbox.new(admin_user:, now:)

    expect(inbox.unread_count).to eq(1)
    expect(inbox.notifications(filter: "all")).to contain_exactly(active, read)
    expect(inbox.notifications(filter: "requires_action")).to contain_exactly(active)
    expect(inbox.notifications(filter: "fyi")).to contain_exactly(read)
    expect(inbox.notifications(filter: "unread")).to contain_exactly(active)
    expect(inbox.notifications(filter: "snoozed")).to contain_exactly(snoozed)
    expect(inbox.notifications(filter: "dismissed")).to contain_exactly(dismissed)
  end

  it "mutates recipient state durably even when best-effort Cable delivery fails" do
    notification = create_notification
    allow(ActivityCenterChannel).to receive(:broadcast_to).and_raise(IOError, "cable unavailable")

    expect do
      ActivityCenter::MutateState.call(notification:, mutation: "snooze", now:)
    end.not_to raise_error
    expect(notification.reload.snoozed_until).to eq(now + 1.hour)

    ActivityCenter::MutateState.call(notification:, mutation: "dismiss", now:)
    expect(notification.reload.dismissed_at).to eq(now)

    ActivityCenter::MutateState.call(notification:, mutation: "restore", now:)
    expect(notification.reload).to have_attributes(dismissed_at: nil, snoozed_until: nil)
  end

  it "completes the Rails-owned workflow record rather than accepting domain truth from notification params" do
    workflow_item = create(:workflow_item, state: "review", position: 0)
    notification = create_notification(attention_kind: "requires_action", priority: "high", record: workflow_item)
    notification.event.update!(params: notification.params.merge("workflow_item_id" => -1, "target_state" => "backlog"))

    expect { ActivityCenter::PerformAction.call(notification:) }
      .to change { workflow_item.reload.state }.from("review").to("done")
    expect(notification.reload).to be_read
    expect(ActivityCenter::Serializer.new(notification).as_json.fetch(:availableAction)).to be_nil
  end

  it "rejects actions when canonical domain truth does not expose the transition" do
    notification = create_notification(record: create(:workflow_item, state: "ready"))

    expect { ActivityCenter::PerformAction.call(notification:) }
      .to raise_error(ActivityCenter::UnsupportedAction, /no longer has an available action/)
  end

  it "serializes explicit attention state and the canonical action endpoint" do
    workflow_item = create(:workflow_item, state: "review", position: 0)
    notification = create_notification(attention_kind: "requires_action", priority: "high", record: workflow_item)
    serialized = ActivityCenter::Serializer.new(notification).as_json

    expect(serialized).to include(
      attentionKind: "requires_action",
      dismissed: false,
      priority: "high",
      snoozedUntil: nil
    )
    expect(serialized.fetch(:availableAction)).to include(label: "Complete review")
  end

  it "enforces bounded attention values and keeps the recipient query indexed" do
    notification = create_notification

    expect { notification.update_column(:attention_kind, "business_rule") }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect { notification.update_column(:priority, "urgent") }
      .to raise_error(ActiveRecord::StatementInvalid)
    expect(ActiveRecord::Base.connection.index_exists?(
      :noticed_notifications,
      %i[recipient_type recipient_id dismissed_at snoozed_until read_at],
      name: "index_noticed_notifications_on_recipient_attention"
    )).to be(true)
  end
end
