# spec/services/hierarchy_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hierarchy services" do
  let(:admin) { create(:admin_user) }

  it "queries only direct owner-scoped children with generated URLs" do
    root = create(:hierarchy_node, admin_user: admin)
    child = create(:hierarchy_node, admin_user: admin, parent: root)
    outsider_root = create(:hierarchy_node)
    create(:hierarchy_node, admin_user: outsider_root.admin_user, parent: outsider_root)

    payload = Hierarchy::Query.new(admin_user: admin, parent_id: root.id).as_json

    expect(payload.fetch(:nodes).pluck(:id)).to eq([ child.id.to_s ])
    expect(payload.dig(:nodes, 0)).to include(:childrenUrl, :moveUrl, breadcrumbs: [ { id: root.id.to_s, title: root.title } ])
  end

  it "rejects an unauthorized parent" do
    root = create(:hierarchy_node, admin_user: admin)

    expect do
      Hierarchy::Reparent.call(admin_user: admin, node: root, parent_id: create(:hierarchy_node).id, position: 0, expected_lock_version: 0)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "persists valid moves and rejects cycles, malformed positions, and stale versions" do
    root = create(:hierarchy_node, admin_user: admin)
    child = create(:hierarchy_node, admin_user: admin, parent: root)
    sibling = create(:hierarchy_node, admin_user: admin)

    moved = Hierarchy::Reparent.call(admin_user: admin, node: sibling, parent_id: root.id, position: 2, expected_lock_version: 0)
    expect(moved.reload).to have_attributes(parent: root, position: 2, lock_version: 1)

    expect do
      Hierarchy::Reparent.call(admin_user: admin, node: root, parent_id: child.id, position: 0, expected_lock_version: 0)
    end.to raise_error(ActiveRecord::RecordInvalid, /cycle/)
    expect do
      Hierarchy::Reparent.call(admin_user: admin, node: child, parent_id: nil, position: "bad", expected_lock_version: 0)
    end.to raise_error(ActiveRecord::RecordInvalid, /Position/)
    expect do
      Hierarchy::Reparent.call(admin_user: admin, node: child, parent_id: nil, position: 0, expected_lock_version: 99)
    end.to raise_error(Hierarchy::Reparent::StaleWrite)
  end

  it "seeds the deterministic hierarchy idempotently" do
    expect { Hierarchy::Seed.call(admin_user: admin) }.to change(admin.hierarchy_nodes, :count).by(8)
    expect { Hierarchy::Seed.call(admin_user: admin) }.not_to change(admin.hierarchy_nodes, :count)
  end
end
