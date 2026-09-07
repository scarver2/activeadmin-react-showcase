# app/services/safe_terminal/create.rb
# frozen_string_literal: true

module SafeTerminal
  class Create
    def self.call(admin_user:, command_key:, idempotency_key:)
      definition = Commands.fetch(command_key)
      execution, output, created = admin_user.with_lock do
        existing = admin_user.terminal_executions.find_by(idempotency_key:)
        next [ existing, nil, false ] if existing

        created_execution = admin_user.terminal_executions.create!(
          command_key:,
          display_command: command_key,
          idempotency_key:
        )
        initial_output = created_execution.outputs.create!(
          occurred_at: created_execution.created_at,
          sequence: 1,
          stream: "system",
          text: "Queued allowlisted command: #{definition.fetch(:label)}."
        )
        [ created_execution, initial_output, true ]
      end
      if created
        Broadcast.call(execution, output)
        SafeTerminalDemoJob.perform_later(execution.id)
      end
      execution
    rescue ActiveRecord::RecordNotUnique
      admin_user.terminal_executions.find_by!(idempotency_key:)
    end
  end
end
