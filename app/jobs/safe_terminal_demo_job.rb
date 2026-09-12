# app/jobs/safe_terminal_demo_job.rb
# frozen_string_literal: true

class SafeTerminalDemoJob < ApplicationJob
  queue_as :default

  def perform(execution_id)
    execution = TerminalExecution.find_by(id: execution_id)
    return unless execution

    definition = SafeTerminal::Commands.fetch(execution.command_key)
    SafeTerminal::Append.call(execution:, state: "running", stream: "system", text: "Starting deterministic demo command.")
    definition.fetch(:steps).each do |stream, text|
      pause
      return if execution.reload.terminal?

      SafeTerminal::Append.call(execution:, state: "running", stream:, text:)
    end
    SafeTerminal::Append.call(
      execution:,
      state: "completed",
      stream: "system",
      text: "Command completed successfully."
    )
  rescue StandardError => e
    Rails.logger.error("Safe terminal demo failed: #{e.class}: #{e.message}")
    SafeTerminal::Append.call(
      execution:,
      state: "failed",
      stream: "stderr",
      text: "The deterministic demo command failed safely."
    ) if execution
  end

  private

  def pause
    sleep Float(ENV.fetch("SHOWCASE_TERMINAL_STEP_DELAY", "0.2"))
  end
end
