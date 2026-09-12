# app/admin/safe_terminal.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Safe Terminal" do
  menu label: "Safe Terminal", parent: "Operations", priority: 2

  content title: "Safe Terminal" do
    executions = current_admin_user.terminal_executions.includes(:outputs).recent_first.limit(10)
    routes = Rails.application.routes.url_helpers

    panel "A terminal-shaped interface, never a shell" do
      para "Rails accepts only fixed application command keys. Solid Queue runs deterministic demo steps and Solid Cable transports durable output."
    end

    react_component(
      "SafeTerminal",
      props: {
        commands: SafeTerminal::Commands.options,
        createUrl: routes.admin_terminal_executions_path,
        executions: executions.map { |execution| SafeTerminal::Serializer.new(execution).as_json }
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "The allowlisted command catalog and durable transcripts remain available without JavaScript."),
          form_with(url: routes.admin_terminal_executions_path, method: :post) do |form|
            safe_join([
              form.label(:command_key, "Allowlisted demo command"),
              form.select(:command_key, SafeTerminal::Commands.options.map { |command| [ command.fetch(:label), command.fetch(:key) ] }),
              form.hidden_field(:idempotency_key, value: SecureRandom.uuid),
              form.submit("Run safe command")
            ])
          end,
          content_tag(:ol) do
            safe_join(executions.map do |execution|
              content_tag(:li) do
                safe_join([
                  content_tag(:strong, "#{execution.display_command} — #{execution.state}"),
                  content_tag(:pre, execution.outputs.map(&:text).join("\n")),
                  if execution.terminal?
                    ""
                  else
                    button_to("Cancel", routes.cancel_admin_terminal_execution_path(execution.public_id), method: :post)
                  end
                ])
              end
            end)
          end,
          content_tag(:h3, "Ruby"),
          content_tag(:p, "SafeTerminal::Commands validates an exact registry key and Solid Queue performs fixed application work."),
          content_tag(:h3, "JavaScript"),
          content_tag(:p, "React owns xterm.js input and cursor-based Solid Cable replay."),
          content_tag(:h3, "Architecture"),
          content_tag(:p, "SQLite transcript → Solid Queue demo → Solid Cable transport → xterm.js presentation."),
          link_to("Read the safe-terminal guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/safe-terminal.md")
        ])
      },
      class: "mt-6"
    )
  end
end
