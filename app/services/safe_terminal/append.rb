# app/services/safe_terminal/append.rb
# frozen_string_literal: true

module SafeTerminal
  class Append
    def self.call(execution:, state:, stream:, text:)
      output = execution.with_lock do
        execution.reload
        next if execution.terminal?

        now = Time.current
        attributes = { state: }
        attributes[:started_at] = execution.started_at || now if state == "running"
        attributes[:finished_at] = now if state.in?(TerminalExecution::TERMINAL_STATES)
        execution.update!(attributes)
        execution.outputs.create!(
          occurred_at: now,
          sequence: execution.outputs.maximum(:sequence).to_i + 1,
          stream:,
          text:
        )
      end
      Broadcast.call(execution, output) if output
      output
    end
  end
end
