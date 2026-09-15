# spec/models/hierarchy_node_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe HierarchyNode do
  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_presence_of(:title) }

  it "delegates generic tree navigation to Ancestry and applies sibling ordering" do
    root = create(:hierarchy_node)
    later = create(:hierarchy_node, admin_user: root.admin_user, parent: root, position: 2)
    earlier = create(:hierarchy_node, admin_user: root.admin_user, parent: root, position: 1)

    expect(root.children.ordered).to eq([ earlier, later ])
    expect(later.ancestors).to eq([ root ])
    expect(later).to have_attributes(ancestry: "/#{root.id}/", ancestry_depth: 1)
    expect(root).to be_ancestor_of(later)
  end

  it "keeps ownership policy local and delegates cycle prevention to Ancestry" do
    root = create(:hierarchy_node)
    child = create(:hierarchy_node, admin_user: root.admin_user, parent: root)
    outsider = create(:hierarchy_node)

    child.parent = outsider
    expect(child).not_to be_valid
    child.reload
    root.parent = child
    expect(root).not_to be_valid
    expect(root.errors[:base]).to include("Hierarchy node cannot be a descendant of itself.")
  end

  it "bounds hierarchy depth" do
    root = create(:hierarchy_node)
    level_two = create(:hierarchy_node, admin_user: root.admin_user, parent: root)
    level_three = create(:hierarchy_node, admin_user: root.admin_user, parent: level_two)
    level_four = create(:hierarchy_node, admin_user: root.admin_user, parent: level_three)

    too_deep = build(:hierarchy_node, admin_user: root.admin_user, parent: level_four)
    expect(too_deep).not_to be_valid
    expect(too_deep.errors[:ancestry_depth]).to be_present

    branch = create(:hierarchy_node, admin_user: root.admin_user)
    leaf = create(:hierarchy_node, admin_user: root.admin_user, parent: branch)
    branch.reload.parent = level_three
    expect(branch).not_to be_valid
    expect(branch.errors[:ancestry_depth]).to be_present
    expect(leaf.reload.parent).to eq(branch)
  end

  it "exposes only explicit ActiveAdmin search fields" do
    expect(described_class.ransackable_associations).to eq([])
    expect(described_class.ransackable_attributes).to include("ancestry", "ancestry_depth", "position", "title")
  end
end
