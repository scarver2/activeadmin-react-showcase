# app/services/safe_terminal/cancel.rb
# frozen_string_literal: true

module SafeTerminal
  class Cancel
    def self.call(execution:)
      output = execution.with_lock do
        execution.reload
        next if execution.terminal?

        now = Time.current
        execution.update!(cancel_requested_at: now, finished_at: now, state: "cancelled")
        execution.outputs.create!(
          occurred_at: now,
          sequence: execution.outputs.maximum(:sequence).to_i + 1,
          stream: "system",
          text: "Cancellation accepted; no further demo steps will run."
        )
      end
      Broadcast.call(execution, output) if output
      execution.reload
    end
  end
end
