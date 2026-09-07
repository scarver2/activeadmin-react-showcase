# spec/models/terminal_execution_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe TerminalExecution do
  subject(:execution) { build(:terminal_execution) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to have_many(:outputs).dependent(:destroy) }
  it { is_expected.to validate_inclusion_of(:state).in_array(described_class::STATES) }
  it { is_expected.to validate_length_of(:idempotency_key).is_at_most(100) }

  it "assigns a public id and scopes its broadcast key to its owner" do
    execution.save!

    expect(execution.public_id).to be_present
    expect(execution.broadcast_key).to eq("terminal-executions:admin-user:#{execution.admin_user_id}:#{execution.public_id}")
    expect(execution).not_to be_terminal
    execution.update!(state: "completed")
    expect(execution).to be_terminal
  end

  it "rejects command keys outside the application registry" do
    execution.command_key = "sh -c whoami"

    expect(execution).not_to be_valid
  end
end
