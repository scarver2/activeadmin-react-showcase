# spec/models/operation_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operation do
  subject(:operation) { build(:operation) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { is_expected.to validate_inclusion_of(:state).in_array(described_class::STATES) }

  it "assigns an opaque public identifier" do
    operation.save!

    expect(operation.public_id).to match(/\A[0-9a-f-]{36}\z/)
  end

  it "identifies terminal and retryable states" do
    operation.state = "failed"

    expect(operation).to be_terminal
    expect(operation).to be_retryable
    expect(operation).not_to be_cancelable
  end

  it "identifies active states and provides a sequence-zero snapshot before its first event" do
    operation.save!

    expect(operation).not_to be_terminal
    expect(operation).not_to be_retryable
    expect(operation).to be_cancelable
    expect(operation.latest_envelope).to include(sequence: 0, state: "queued", operation_id: operation.public_id)
  end

  it "uses the latest persisted event envelope" do
    operation.save!
    event = operation.events.create!(idempotency_key: "#{operation.public_id}:1", message: "Queued", occurred_at: Time.current,
                                     progress: 0, sequence: 1, state: "queued")

    expect(operation.latest_envelope).to eq(event.envelope)
  end
end
