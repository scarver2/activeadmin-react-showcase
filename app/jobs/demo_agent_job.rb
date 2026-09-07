# app/jobs/demo_agent_job.rb
# frozen_string_literal: true

class DemoAgentJob < ApplicationJob
  queue_as :default

  STEPS = [
    [ "status", "Reading authorized showcase records", 15, {} ],
    [ "status", "Comparing account health signals", 35, {} ],
    [ "response", "The deterministic agent found six synthetic accounts and compared their recent activity. ", 55, {} ],
    [ "citation", "Account explorer", 70, { "label" => "Authorized account dataset", "url" => "/admin/data_explorer" } ],
    [ "response", "The strongest next action is to inspect trial accounts before reviewing aggregate trends.", 85, {} ]
  ].freeze

  def perform(run_id)
    run = AgentRun.find_by(id: run_id)
    return unless run

    run.update!(state: "running")
    STEPS.each do |kind, content, progress, metadata|
      return cancel(run) if run.reload.cancel_requested_at?

      pause
      AgentConsole::RecordEvent.call(run:, kind:, content:, progress:, metadata:, state: "running")
    end
    return cancel(run) if run.reload.cancel_requested_at?

    summary = "Review trial accounts, then compare the analytics trend."
    AgentConsole::RecordEvent.call(
      run:, kind: "result", content: summary, progress: 100,
      metadata: { "sources" => 1 }, state: "completed", summary:
    )
  end

  private

  def cancel(run)
    AgentConsole::RecordEvent.call(
      run:, kind: "status", content: "Agent run cancelled", progress: run.progress, state: "cancelled"
    )
  end

  def pause
    sleep Float(ENV.fetch("SHOWCASE_AGENT_STEP_DELAY", "0.2"))
  end
end
