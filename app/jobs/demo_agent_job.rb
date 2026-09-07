# app/jobs/demo_agent_job.rb
# frozen_string_literal: true

class DemoAgentJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = AgentRun.find_by(id: run_id)
    return unless run

    run.update!(state: "running")
    provider.each_event do |event|
      return cancel(run) if run.reload.cancel_requested_at?

      pause
      AgentConsole::RecordEvent.call(
        run:, kind: event.kind, content: event.content, progress: event.progress, metadata: event.metadata, state: "running"
      )
    end
    return cancel(run) if run.reload.cancel_requested_at?

    summary = provider.result
    AgentConsole::RecordEvent.call(
      run:, kind: "result", content: summary, progress: 100,
      metadata: { "sources" => 1 }, state: "completed", summary:
    )
  end

  private

  def provider
    @provider ||= Showcase::Agent::DeterministicProvider.new
  end

  def cancel(run)
    AgentConsole::RecordEvent.call(
      run:, kind: "status", content: "Agent run cancelled", progress: run.progress, state: "cancelled"
    )
  end

  def pause
    sleep Float(ENV.fetch("SHOWCASE_AGENT_STEP_DELAY", "0.2"))
  end
end
