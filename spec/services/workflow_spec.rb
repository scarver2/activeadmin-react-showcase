# spec/services/workflow_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workflow do
  it "moves an item transactionally and resequences both columns" do
    first = create(:workflow_item, title: "First", state: "backlog", position: 0)
    second = create(:workflow_item, title: "Second", state: "backlog", position: 1)
    ready = create(:workflow_item, title: "Ready", state: "ready", position: 0)

    moved = Workflow::Move.call(item: first, state: "ready", position: 0)

    expect(moved.reload.attributes.values_at("state", "position")).to eq([ "ready", 0 ])
    expect(second.reload.position).to eq(0)
    expect(ready.reload.position).to eq(1)
  end

  it "reorders within one column" do
    first = create(:workflow_item, title: "First", position: 0)
    second = create(:workflow_item, title: "Second", position: 1)

    Workflow::Move.call(item: first, state: "backlog", position: 1)

    expect([ second.reload.position, first.reload.position ]).to eq([ 0, 1 ])
  end

  it "rejects unknown states, malformed positions, and out-of-bounds positions" do
    item = create(:workflow_item, position: 0)

    expect { Workflow::Move.call(item:, state: "invented", position: 0) }.to raise_error(ActiveRecord::RecordInvalid, /State is not a supported/)
    expect { Workflow::Move.call(item:, state: "ready", position: "later") }.to raise_error(ActiveRecord::RecordInvalid, /Position must be an integer/)
    expect { Workflow::Move.call(item:, state: "ready", position: 1) }.to raise_error(ActiveRecord::RecordInvalid, /Position must be between 0 and 0/)
  end

  it "seeds demonstration records idempotently" do
    Workflow::Seed.call
    Workflow::Seed.call

    expect(WorkflowItem.count).to eq(5)
    expect(WorkflowItem.pluck(:state)).to contain_exactly(*WorkflowItem::STATES)
  end
end
