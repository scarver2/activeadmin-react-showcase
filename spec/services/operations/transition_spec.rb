# spec/services/operations/transition_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Operations::Transition do
  let(:operation) { create(:operation) }

  it "persists and broadcasts monotonically sequenced progress" do
    operation.events.create!(idempotency_key: "#{operation.public_id}:1", message: "Queued", occurred_at: Time.current,
                             progress: 0, sequence: 1, state: "queued")
    allow(ActionCable.server).to receive(:broadcast)

    event = described_class.call(operation:, state: "running", progress: 20, message: "Working")

    expect(event).to have_attributes(sequence: 2, idempotency_key: "#{operation.public_id}:2")
    expect(operation.reload).to have_attributes(state: "running", progress: 20, message: "Working")
    expect(ActionCable.server).to have_received(:broadcast).with(operation.broadcast_key, event.envelope)
  end

  it "rejects transitions after a terminal state" do
    operation.update!(state: "completed", progress: 100)

    expect do
      described_class.call(operation:, state: "running", progress: 50, message: "Too late")
    end.to raise_error(ArgumentError, /cannot transition/)
  end
end
