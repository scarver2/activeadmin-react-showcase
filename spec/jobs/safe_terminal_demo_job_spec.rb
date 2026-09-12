# spec/jobs/safe_terminal_demo_job_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SafeTerminalDemoJob do
  around do |example|
    ClimateControl.modify(SHOWCASE_TERMINAL_STEP_DELAY: "0") { example.run }
  end

  it "streams only the selected fixed definition and completes" do
    execution = create(:terminal_execution, command_key: "showcase:status", display_command: "showcase:status")

    expect(Kernel).not_to receive(:system)
    expect(Process).not_to receive(:spawn)
    described_class.perform_now(execution.id)

    expect(execution.reload.state).to eq("completed")
    expect(execution.outputs.pluck(:sequence)).to eq([ 1, 2, 3, 4, 5 ])
    expect(execution.outputs.pluck(:text)).to include("Rails application: ready.", "Command completed successfully.")
  end

  it "stops when cancellation wins between bounded steps" do
    execution = create(:terminal_execution)
    allow_any_instance_of(described_class).to receive(:pause) { SafeTerminal::Cancel.call(execution:) }

    described_class.perform_now(execution.id)

    expect(execution.reload.state).to eq("cancelled")
    expect(execution.outputs.last.text).to include("Cancellation accepted")
  end

  it "ignores a missing execution and records a safe failure" do
    expect { described_class.perform_now(-1) }.not_to raise_error
    execution = create(:terminal_execution)
    allow(SafeTerminal::Commands).to receive(:fetch).and_raise("unexpected")
    allow(Rails.logger).to receive(:error)

    described_class.perform_now(execution.id)

    expect(execution.reload.state).to eq("failed")
    expect(execution.outputs.last).to have_attributes(stream: "stderr", text: "The deterministic demo command failed safely.")
  end
end
