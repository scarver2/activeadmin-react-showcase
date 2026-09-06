# spec/channels/operations_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperationsChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }
  let(:operation) { Operations::Create.call(admin_user:, kind: "successful_demo", request_idempotency_key: "request-1") }

  before { stub_connection current_admin_user: admin_user }

  it "authorizes and holds delivery until confirmed-client resume" do
    subscribe(operation_id: operation.public_id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(operation.broadcast_key)
    expect(transmissions).to be_empty

    perform :resume, after_sequence: 0
    expect(transmissions.last).to include("operation_id" => operation.public_id, "sequence" => 1)
  end

  it "rejects another administrator's operation" do
    other_operation = Operations::Create.call(admin_user: create(:admin_user), kind: "successful_demo", request_idempotency_key: "request-2")

    subscribe(operation_id: other_operation.public_id)

    expect(subscription).to be_rejected
  end

  it "replays missed events in sequence before accepting live delivery" do
    Operations::Transition.call(operation:, state: "running", progress: 20, message: "Working")
    Operations::Transition.call(operation:, state: "running", progress: 40, message: "Still working")
    subscribe(operation_id: operation.public_id, after_sequence: 1)
    perform :resume, after_sequence: 1

    expect(transmissions.pluck("sequence")).to eq([ 2, 3 ])
  end

  it "orders an event buffered after stream activation behind persistent replay" do
    Operations::Transition.call(operation:, state: "running", progress: 20, message: "Persisted first")
    subscribe(operation_id: operation.public_id)
    buffered = Operations::Transition.call(operation:, state: "running", progress: 40, message: "Committed during activation")
    subscription.send(:deliver_or_buffer, buffered.envelope.stringify_keys)

    perform :resume, after_sequence: 1

    expect(transmissions.pluck("sequence")).to eq([ 2, 3 ])
  end

  it "ignores invalid and repeated stale resume cursors" do
    subscribe(operation_id: operation.public_id)

    perform :resume, after_sequence: -1
    perform :resume, after_sequence: "invalid"
    expect(transmissions).to be_empty

    perform :resume, after_sequence: 0
    perform :resume, after_sequence: 0
    expect(transmissions.pluck("sequence")).to eq([ 1 ])
  end
end
