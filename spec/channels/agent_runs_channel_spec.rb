# spec/channels/agent_runs_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgentRunsChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }
  let(:run) { create(:agent_run, admin_user:) }

  before { stub_connection current_admin_user: admin_user }

  it "authorizes ownership and replays unseen events in order without duplicate cursors" do
    AgentConsole::RecordEvent.call(run:, kind: "status", content: "Queued", progress: 0)
    AgentConsole::RecordEvent.call(run:, kind: "response", content: "Finding", progress: 50, state: "running")
    subscribe(run_id: run.public_id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(run.broadcast_key)

    perform :resume, after_sequence: 0
    perform :resume, after_sequence: 0
    expect(transmissions.pluck("sequence")).to eq([ 1, 2 ])
  end

  it "rejects another administrator's run and ignores invalid cursors" do
    subscribe(run_id: create(:agent_run).public_id)
    expect(subscription).to be_rejected

    subscribe(run_id: run.public_id)
    perform :resume, after_sequence: "invalid"
    perform :resume, after_sequence: -1
    expect(transmissions).to be_empty
  end
end
