# spec/services/safe_terminal_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SafeTerminal do
  let(:admin_user) { create(:admin_user) }

  before do
    allow(ActionCable.server).to receive(:broadcast)
    allow(SafeTerminalDemoJob).to receive(:perform_later)
  end

  it "exposes only fixed deterministic command definitions" do
    expect(SafeTerminal::Commands.keys).to contain_exactly(
      "showcase:backup:verify",
      "showcase:deploy:plan",
      "showcase:status"
    )
    expect(SafeTerminal::Commands.options).to all(include(:key, :label))
    expect { SafeTerminal::Commands.fetch("status; uname -a") }.to raise_error(
      SafeTerminal::Commands::Unsupported,
      "Command is not allowlisted"
    )
  end

  it "persists before enqueue and deduplicates a command request" do
    first = SafeTerminal::Create.call(admin_user:, command_key: "showcase:status", idempotency_key: "request-1")
    second = SafeTerminal::Create.call(admin_user:, command_key: "showcase:status", idempotency_key: "request-1")

    expect(second).to eq(first)
    expect(first.outputs.sole.text).to include("Queued allowlisted command")
    expect(SafeTerminalDemoJob).to have_received(:perform_later).with(first.id).once
    expect(ActionCable.server).to have_received(:broadcast).once
  end

  it "keeps persistence and enqueue independent from Cable availability" do
    allow(ActionCable.server).to receive(:broadcast).and_raise("Cable unavailable")
    allow(Rails.logger).to receive(:error)

    execution = SafeTerminal::Create.call(admin_user:, command_key: "showcase:status", idempotency_key: "request-2")

    expect(execution).to be_persisted
    expect(SafeTerminalDemoJob).to have_received(:perform_later).with(execution.id)
    expect(Rails.logger).to have_received(:error).with(/Cable broadcast failed/)
  end

  it "appends monotonic durable output and terminal state" do
    execution = create(:terminal_execution)

    output = SafeTerminal::Append.call(execution:, state: "running", stream: "stdout", text: "Working")
    SafeTerminal::Append.call(execution:, state: "completed", stream: "system", text: "Done")

    expect(output.sequence).to eq(1)
    expect(execution.reload).to have_attributes(state: "completed", started_at: be_present, finished_at: be_present)
    expect(SafeTerminal::Append.call(execution:, state: "running", stream: "stdout", text: "Too late")).to be_nil
  end

  it "cancels once under the execution lock" do
    execution = create(:terminal_execution)

    first = SafeTerminal::Cancel.call(execution:)
    second = SafeTerminal::Cancel.call(execution:)

    expect(first).to have_attributes(state: "cancelled", cancel_requested_at: be_present)
    expect(second.outputs.count).to eq(1)
    expect(second.outputs.sole.text).to include("Cancellation accepted")
  end
end
