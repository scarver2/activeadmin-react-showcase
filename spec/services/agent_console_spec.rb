# spec/services/agent_console_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgentConsole do
  it "creates durable state before enqueueing deterministic work" do
    admin = create(:admin_user)
    expect do
      run = AgentConsole::Create.call(admin_user: admin, prompt: "  Inspect accounts  ")
      expect(run).to have_attributes(prompt: "Inspect accounts", state: "queued")
      expect(run.events.first).to have_attributes(kind: "status", sequence: 1)
    end.to have_enqueued_job(DemoAgentJob)
  end

  it "persists an event when Cable delivery fails" do
    run = create(:agent_run)
    allow(ActionCable.server).to receive(:broadcast).and_raise("offline")
    allow(Rails.logger).to receive(:error)

    expect do
      AgentConsole::RecordEvent.call(run:, kind: "status", content: "Working", progress: 10, state: "running")
    end.to change(run.events, :count).by(1)
    expect(Rails.logger).to have_received(:error).with(/Cable broadcast failed/)
  end

  it "runs the deterministic response through citation and terminal result" do
    run = create(:agent_run)
    AgentConsole::RecordEvent.call(run:, kind: "status", content: "Queued", progress: 0)
    provider = instance_double(Showcase::Agent::DeterministicProvider, result: "Review trial accounts, then compare the analytics trend.")
    allow(provider).to receive(:each_event).and_yield(
      Showcase::Agent::DeterministicProvider::Event.new(
        kind: "citation", content: "Accounts", progress: 70, metadata: { "url" => "/admin/data_explorer" }
      )
    )
    allow(Showcase::Agent::DeterministicProvider).to receive(:new).and_return(provider)
    allow_any_instance_of(DemoAgentJob).to receive(:pause)

    described_class # keep namespace as the subject of this focused service spec
    DemoAgentJob.perform_now(run.id)

    expect(run.reload).to have_attributes(state: "completed", progress: 100)
    expect(run.events.pluck(:kind)).to eq(%w[status citation result])
    expect(run.summary).to eq("Review trial accounts, then compare the analytics trend.")
  end

  it "exposes a fixed provider contract without credentials" do
    provider = Showcase::Agent::DeterministicProvider.new
    events = []
    provider.each_event { |event| events << event }
    expect(events.map(&:kind)).to include("status", "response", "citation")
    expect(events.map(&:progress)).to eq(events.map(&:progress).sort)
    expect(provider.result).to include("Review trial accounts")
  end

  it "honors persisted cancellation intent" do
    run = create(:agent_run, cancel_requested_at: Time.current)
    allow_any_instance_of(DemoAgentJob).to receive(:pause)
    DemoAgentJob.perform_now(run.id)
    expect(run.reload).to have_attributes(state: "cancelled", summary: nil)
  end
end
