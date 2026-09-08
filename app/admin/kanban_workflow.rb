# app/admin/kanban_workflow.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Kanban Workflow" do
  menu label: "Kanban Workflow", parent: "Collaboration", priority: 2

  content title: "Persisted Kanban Workflow" do
    items = WorkflowItem.ordered

    panel "Rails-authoritative workflow" do
      para "Drag or use accessible move controls to propose a transition. Rails validates and persists the canonical state and order."
    end

    react_component(
      "KanbanWorkflow",
      props: { items: items.map { |item| Workflow::Serializer.new(item).as_json } },
      fallback: lambda {
        safe_join(WorkflowItem::STATES.map do |state|
          content_tag(:section) do
            safe_join([
              content_tag(:h2, state.humanize),
              content_tag(:ol) do
                safe_join(items.select { |item| item.state == state }.map do |item|
                  content_tag(:li) do
                    safe_join([
                      content_tag(:strong, item.title),
                      content_tag(:p, item.context),
                      form_with(url: admin_workflow_item_move_path(item), method: :patch) do |form|
                        safe_join([
                          form.label(:state, "State"),
                          form.select(:state, options_for_select(WorkflowItem::STATES.map { |value| [ value.humanize, value ] }, item.state)),
                          form.label(:position, "Position"),
                          form.number_field(:position, min: 0, value: item.position),
                          form.submit("Move item")
                        ])
                      end
                    ])
                  end
                end)
              end
            ])
          end
        end)
      },
      class: "mt-6"
    )
  end
end
