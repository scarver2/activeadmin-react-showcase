# spec/models/hierarchy_node_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe HierarchyNode do
  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to belong_to(:parent).optional }
  it { is_expected.to validate_presence_of(:title) }

  it "orders children and exposes ancestors" do
    root = create(:hierarchy_node)
    later = create(:hierarchy_node, admin_user: root.admin_user, parent: root, position: 2)
    earlier = create(:hierarchy_node, admin_user: root.admin_user, parent: root, position: 1)

    expect(root.children).to eq([ earlier, later ])
    expect(later.ancestors).to eq([ root ])
  end

  it "rejects cross-owner parents and cycles" do
    root = create(:hierarchy_node)
    child = create(:hierarchy_node, admin_user: root.admin_user, parent: root)
    outsider = create(:hierarchy_node)

    child.parent = outsider
    expect(child).not_to be_valid
    child.reload
    root.parent = child
    expect(root).not_to be_valid
    expect(root.errors[:parent]).to include("cannot create a cycle")
  end

  it "bounds hierarchy depth" do
    root = create(:hierarchy_node)
    level_two = create(:hierarchy_node, admin_user: root.admin_user, parent: root)
    level_three = create(:hierarchy_node, admin_user: root.admin_user, parent: level_two)
    level_four = create(:hierarchy_node, admin_user: root.admin_user, parent: level_three)

    too_deep = build(:hierarchy_node, admin_user: root.admin_user, parent: level_four)
    expect(too_deep).not_to be_valid
    expect(too_deep.errors[:parent]).to include("would exceed four levels")
  end

  it "exposes only explicit ActiveAdmin search fields" do
    expect(described_class.ransackable_associations).to eq([])
    expect(described_class.ransackable_attributes).to include("parent_id", "position", "title")
  end
end
