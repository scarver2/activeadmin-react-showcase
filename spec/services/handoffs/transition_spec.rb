# spec/services/handoffs/transition_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Handoffs::Transition do
  let(:admin_user) { create(:admin_user) }
  let(:item) { admin_user.handoff_items.create!(title: "Synthetic checklist") }

  def command(action, **options)
    described_class.call(item:, admin_user:, action:, command_id: SecureRandom.uuid, version: item.reload.lock_version, **options)
  end

  it "requires human approval after three bounded automated steps" do
    command("assign")
    3.times { command("advance") }
    expect(item).to have_attributes(state: "approval", progress: 75)
    expect(item.events.last).to have_attributes(actor: "deterministic_agent")
    expect { command("advance") }.to raise_error(described_class::Conflict)
    command("approve")
    expect(item).to have_attributes(state: "completed", progress: 100)
    expect(item.events.last.actor).to eq("human")
    expect(item.events.pluck(:sequence)).to eq((1..5).to_a)
    expect { command("cancel") }.to raise_error(described_class::Conflict)
  end

  it "retains evidence on intervention and allows deliberate reassignment" do
    command("assign")
    command("advance")
    command("hand_back")
    expect(item).to have_attributes(state: "human", progress: 25)
    command("assign")
    expect(item.progress).to eq(0)
    expect(item.events.count).to eq(4)
    3.times { command("advance") }
    command("hand_back")
    expect(item.state).to eq("human")
  end

  it "makes same-command retries idempotent while rejecting identity reuse" do
    id = SecureRandom.uuid
    command("assign", command_id: id)
    command("assign", command_id: id, version: 0)
    expect(item.events.count).to eq(1)
    expect { command("cancel", command_id: id) }.to raise_error(described_class::Conflict)
  end

  it "rejects stale completion and late worker steps after cancellation" do
    command("assign")
    version = item.lock_version
    command("cancel")
    expect { command("advance", version:) }.to raise_error(described_class::Conflict)
    expect { command("advance") }.to raise_error(described_class::Conflict)
    expect(item.reload.state).to eq("cancelled")
    expect(item.events.count).to eq(2)
  end

  it "rejects premature approval, bad identities and another owner" do
    expect { command("approve") }.to raise_error(described_class::Conflict)
    expect { command("assign", command_id: "invalid") }.to raise_error(ArgumentError)
    expect { command("assign", admin_user: create(:admin_user)) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(item.events).to be_empty
    command("cancel")
    expect(item.state).to eq("cancelled")
  end

  it "persists work even if Cable is unavailable" do
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError)
    command("assign")
    expect(item.reload.state).to eq("agent")
    expect(item.events.count).to eq(1)
  end

  it "turns optimistic locking races into a refreshable conflict" do
    allow(item).to receive(:with_lock).and_raise(ActiveRecord::StaleObjectError.new(item, "update"))
    expect { command("assign") }.to raise_error(described_class::Conflict)
  end
end
