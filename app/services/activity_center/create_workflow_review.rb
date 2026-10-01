# app/services/activity_center/create_workflow_review.rb
# frozen_string_literal: true

module ActivityCenter
  class CreateWorkflowReview
    def self.call(admin_user:, now: Time.current)
      item = WorkflowItem.create!(
        context: "Complete this synthetic review from the recipient-specific attention inbox.",
        position: WorkflowItem.where(state: "review").count,
        state: "review",
        title: "Review actionable notification #{now.to_i}"
      )
      ActivityCenter::Create.call(
        admin_user:,
        attention_kind: "requires_action",
        attributes: {
          body: "A Rails-owned workflow item is waiting for your review.",
          deep_link: Rails.application.routes.url_helpers.admin_kanban_workflow_path,
          kind: "operation",
          occurred_at: now,
          subject: "Workflow review requested"
        },
        enqueue_delivery: false,
        priority: "high",
        record: item
      ).tap { |notification| ActivityCenter::Projection.broadcast(notification) }
    end
  end
end
