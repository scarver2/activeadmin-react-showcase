# app/services/agent_console/create.rb
# frozen_string_literal: true

module AgentConsole
  class Create
    def self.call(admin_user:, prompt:)
      run = admin_user.agent_runs.create!(prompt: prompt.to_s.strip)
      AgentConsole::RecordEvent.call(run:, kind: "status", content: "Queued deterministic analysis", progress: 0)
      DemoAgentJob.perform_later(run.id)
      run
    end
  end
end
