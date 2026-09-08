# spec/requests/admin/workflow_items_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin workflow items" do
  let(:item) { create(:workflow_item, title: "Persisted card", position: 0) }

  it "requires an authenticated administrator" do
    patch admin_workflow_item_move_path(item), params: { state: "ready", position: 0 }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "persists a proposed move and returns the canonical board" do
    sign_in create(:admin_user)

    patch admin_workflow_item_move_path(item), params: { state: "ready", position: 0 }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("items", 0)).to include("title" => "Persisted card", "state" => "ready", "position" => 0)
  end

  it "rejects invalid moves and supports the HTML fallback" do
    sign_in create(:admin_user)
    patch admin_workflow_item_move_path(item), params: { state: "invented", position: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)

    patch admin_workflow_item_move_path(item), params: { state: "ready", position: 0 }
    expect(response).to redirect_to(admin_kanban_workflow_path)
  end

  it "renders persisted state without seeding records during the request" do
    sign_in create(:admin_user)
    item

    expect { get admin_kanban_workflow_path }.not_to change(WorkflowItem, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Persisted card", "Move item", "Rails-authoritative workflow")
  end
end
