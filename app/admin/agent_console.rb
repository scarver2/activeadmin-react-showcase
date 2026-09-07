# app/admin/agent_console.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Agent Console" do
  menu label: "Agent Console", parent: "Operations", priority: 3

  content title: "Provider-neutral agent console" do
    runs = current_admin_user.agent_runs.recent_first.limit(10)
    panel "Deterministic, credential-free demonstration" do
      para "Rails authorizes and persists every run. Solid Queue performs bounded work; Solid Cable transports replayable events."
    end
    react_component(
      "AgentConsole",
      props: {
        createUrl: Rails.application.routes.url_helpers.admin_agent_runs_path,
        runs: runs.map { |run| AgentConsole::Serializer.new(run).as_json }
      },
      fallback: lambda {
        safe_join([
          form_with(url: Rails.application.routes.url_helpers.admin_agent_runs_path, method: :post) do |form|
            safe_join([ form.label(:prompt, "Prompt"), form.text_field(:prompt, maxlength: 500, required: true), form.submit("Run demo agent") ])
          end,
          content_tag(:ul) do
            safe_join(runs.map { |run| content_tag(:li, "#{run.prompt} — #{run.state} — #{run.summary || 'No result yet'}") })
          end
        ])
      },
      class: "mt-6"
    )
  end
end
