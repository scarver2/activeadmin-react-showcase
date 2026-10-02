# app/admin/work_handoff.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Work Handoff" do
  menu parent: "Collaboration", priority: 4

  controller do
    before_action :load_item

    private

    def load_item
      @item = current_admin_user.handoff_items.find_by!(public_id: params[:item]) if params[:item].present?
    end
  end

  content title: "Human and AI-Agent Work Handoff" do
    para "Synthetic laboratory. Deterministic demo agent v1; no AI provider, credentials or real work execution. Human approval alone completes work."
    para "Rails persists state and evidence. Refresh safely when live transport is unavailable."
    text_node button_to("Create synthetic work item", admin_handoff_items_path, method: :post,
                        class: "rounded border px-4 py-2 font-medium", form_class: "my-3")
    item = assigns[:item]
    if item
      panel item.title do
        react_component "HandoffLiveHint", props: { itemId: item.public_id, version: item.lock_version,
                                                    refreshUrl: admin_work_handoff_path(item: item.public_id) },
                                         fallback: lambda { para "Live hints unavailable. Refresh durable work state below." }
        para "Assignee: #{item.state.in?(%w[agent approval]) ? 'Deterministic demo agent' : 'Human'}"
        para "State: #{item.state} · Progress: #{item.progress}% · Version: #{item.lock_version}"
        para "Human approval required; automated evidence is not authorization." if item.state == "approval"
        actions = case item.state
        when "human" then { "assign" => "Assign to demo agent", "cancel" => "Cancel work" }
        when "agent" then { "advance" => "Simulate next agent step", "hand_back" => "Take back to human", "cancel" => "Cancel work" }
        when "approval" then { "approve" => "Approve completion", "hand_back" => "Take back to human", "cancel" => "Cancel work" }
        else {}
        end
        actions.each do |action, label|
          text_node button_to(label, admin_handoff_item_path(item.public_id), method: :patch,
                              params: { action_name: action, command_id: SecureRandom.uuid, version: item.lock_version },
                              class: "rounded border px-4 py-2 font-medium", form_class: "inline-block mr-2 my-3")
        end
        h3 "Durable evidence"
        ol do
          item.events.each do |event|
            actor = event.actor == "human" ? "Human operator" : "Deterministic demo agent v1"
            li "#{event.sequence}. #{actor}: #{event.evidence}"
          end
        end
        para link_to("Refresh durable work state", admin_work_handoff_path(item: item.public_id))
      end
    end
    panel "Your recent work" do
      ul do
        current_admin_user.handoff_items.order(created_at: :desc).limit(10).each do |work|
          li link_to("#{work.title} — #{work.state}", admin_work_handoff_path(item: work.public_id))
        end
      end
    end
  end
end
