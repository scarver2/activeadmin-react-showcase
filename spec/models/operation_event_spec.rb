# spec/models/operation_event_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperationEvent do
  let(:operation) { create(:operation) }

  it "emits the gem's monotonic operation envelope" do
    event = described_class.create!(
      idempotency_key: "#{operation.public_id}:1",
      message: "Queued",
      occurred_at: Time.zone.parse("2026-09-06 12:00:00"),
      operation:,
      progress: 0,
      sequence: 1,
      state: "queued"
    )

    expect(event.envelope).to include(
      operation_id: operation.public_id,
      idempotency_key: "#{operation.public_id}:1",
      sequence: 1,
      state: "queued",
      result_metadata: nil
    )
  end
end
