# spec/models/workflow_item_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkflowItem do
  it "persists the fixed workflow vocabulary and bounded positions" do
    expect(build(:workflow_item)).to be_valid
    expect(build(:workflow_item, state: "invented")).not_to be_valid
    expect(build(:workflow_item, position: -1)).not_to be_valid
  end

  it "enforces workflow rules at the database boundary" do
    item = create(:workflow_item)

    expect { item.update_column(:state, "invented") }.to raise_error(ActiveRecord::StatementInvalid)
    expect { item.update_column(:position, -1) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
