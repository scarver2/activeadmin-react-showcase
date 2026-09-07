# spec/channels/safe_terminal_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SafeTerminalChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }
  let(:execution) { create(:terminal_execution, admin_user:) }

  before { stub_connection current_admin_user: admin_user }

  it "authorizes the owner and waits for confirmed-client resume" do
    create(:terminal_output, terminal_execution: execution, sequence: 1)
    subscribe(operation_id: execution.public_id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(execution.broadcast_key)
    expect(transmissions).to be_empty

    perform :resume, after_sequence: 0
    expect(transmissions.pluck("output").pluck("sequence")).to eq([ 1 ])
  end

  it "rejects missing, unauthenticated, and another administrator's execution" do
    subscribe(operation_id: "missing")
    expect(subscription).to be_rejected

    stub_connection current_admin_user: nil
    subscribe(operation_id: execution.public_id)
    expect(subscription).to be_rejected

    stub_connection current_admin_user: create(:admin_user)
    subscribe(operation_id: execution.public_id)
    expect(subscription).to be_rejected
  end

  it "replays in order before buffered live output and deduplicates repeated cursors" do
    first = create(:terminal_output, terminal_execution: execution, sequence: 1, text: "First")
    second = create(:terminal_output, terminal_execution: execution, sequence: 2, text: "Second")
    execution.update!(state: "completed", finished_at: Time.current)
    subscribe(operation_id: execution.public_id)
    buffered = SafeTerminal::Serializer.envelope(execution, second).stringify_keys
    subscription.send(:deliver_or_hold, buffered)

    perform :resume, after_sequence: 0
    perform :resume, after_sequence: 0

    expect(transmissions.pluck("output").pluck("sequence")).to eq([ first.sequence, second.sequence ])
    expect(transmissions.pluck("terminal")).to eq([ false, true ])
  end

  it "delivers fresh live output and ignores invalid cursors" do
    subscribe(operation_id: execution.public_id)
    perform :resume, after_sequence: -1
    perform :resume, after_sequence: "invalid"
    expect(transmissions).to be_empty

    perform :resume, after_sequence: 0
    output = create(:terminal_output, terminal_execution: execution, sequence: 1)
    subscription.send(:deliver_or_hold, SafeTerminal::Serializer.envelope(execution, output).stringify_keys)
    expect(transmissions.pluck("output").pluck("sequence")).to eq([ 1 ])
  end
end
