# spec/models/agent_run_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AgentRun do
  subject(:run) { build(:agent_run) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to have_many(:events).dependent(:destroy) }
  it { is_expected.to validate_inclusion_of(:state).in_array(described_class::STATES) }
  it { is_expected.to validate_length_of(:prompt).is_at_least(1).is_at_most(500) }

  it "assigns a public identifier and recognizes terminal state" do
    run.save!
    expect(run.public_id).to be_present
    expect(run).not_to be_terminal
    run.update!(state: "completed")
    expect(run).to be_terminal
  end
end
