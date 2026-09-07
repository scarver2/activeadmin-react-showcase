# app/services/safe_terminal/serializer.rb
# frozen_string_literal: true

module SafeTerminal
  class Serializer
    def initialize(execution)
      @execution = execution
    end

    def as_json(*)
      routes = Rails.application.routes.url_helpers
      {
        cancelUrl: routes.cancel_admin_terminal_execution_path(execution.public_id),
        commandKey: execution.command_key,
        displayCommand: execution.display_command,
        operationId: execution.public_id,
        outputs: execution.outputs.order(:sequence).map { |output| output_json(output) },
        sequence: execution.outputs.maximum(:sequence).to_i,
        state: execution.state
      }
    end

    def self.envelope(execution, output)
      {
        type: "output",
        operationId: execution.public_id,
        state: execution.state,
        terminal: execution.terminal? && output.sequence == execution.outputs.maximum(:sequence),
        output: output_json(output)
      }
    end

    def self.output_json(output)
      {
        id: output.id,
        occurredAt: output.occurred_at.iso8601(6),
        sequence: output.sequence,
        stream: output.stream,
        text: output.text
      }
    end

    private

    attr_reader :execution

    def output_json(output)
      self.class.output_json(output)
    end
  end
end
