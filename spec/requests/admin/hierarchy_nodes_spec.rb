# spec/requests/admin/hierarchy_nodes_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin hierarchy nodes" do
  let(:admin) { create(:admin_user) }
  let(:headers) { { "ACCEPT" => "application/json" } }

  it "requires authentication" do
    get admin_hierarchy_nodes_path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "loads children and applies a canonical owner-scoped move" do
    sign_in admin
    root = create(:hierarchy_node, admin_user: admin)
    child = create(:hierarchy_node, admin_user: admin, parent: root)
    moving = create(:hierarchy_node, admin_user: admin)

    get admin_hierarchy_nodes_path, params: { parent_id: root.id }, headers: headers
    expect(response.parsed_body.fetch("nodes").pluck("id")).to eq([ child.id.to_s ])

    patch admin_hierarchy_node_path(moving), params: { parent_id: root.id, position: 1, lock_version: 0 }, headers: headers
    expect(response).to have_http_status(:ok)
    expect(moving.reload.parent).to eq(root)
  end

  it "rejects invalid and stale moves and hides other owners" do
    sign_in admin
    root = create(:hierarchy_node, admin_user: admin)
    child = create(:hierarchy_node, admin_user: admin, parent: root)

    patch admin_hierarchy_node_path(root), params: { parent_id: child.id, position: 0, lock_version: 0 }, headers: headers
    expect(response).to have_http_status(:unprocessable_content)

    patch admin_hierarchy_node_path(child), params: { parent_id: nil, position: 0, lock_version: 99 }, headers: headers
    expect(response).to have_http_status(:conflict)

    patch admin_hierarchy_node_path(create(:hierarchy_node)), params: { parent_id: nil, position: 0, lock_version: 0 }, headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it "renders the React page and nested server fallback" do
    sign_in admin
    root = create(:hierarchy_node, admin_user: admin)
    create(:hierarchy_node, admin_user: admin, parent: root)

    get admin_hierarchy_explorer_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("HierarchyExplorer", root.title, "without JavaScript")
  end
end
