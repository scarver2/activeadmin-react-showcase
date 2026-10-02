# spec/requests/admin/handoff_items_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin work handoff" do
  let(:admin_user) { create(:admin_user) }
  let(:item) { admin_user.handoff_items.create!(title: "Synthetic checklist") }

  before { sign_in admin_user }

  it "creates synthetic work and renders native actions and provenance" do
    post admin_handoff_items_path
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(response.body).to include("Assign to demo agent", "no AI provider", "Human approval alone")
    patch admin_handoff_item_path(item.public_id), params: { action_name: "assign", command_id: SecureRandom.uuid, version: 0 }
    follow_redirect!
    expect(response.body).to include("Simulate next agent step", "deterministic demo agent v1")
  end

  it "returns conflicts for stale actions and rejects invalid commands" do
    path = admin_handoff_item_path(item.public_id)
    patch path, params: { action_name: "assign", command_id: SecureRandom.uuid, version: -1 }
    expect(response).to have_http_status(:conflict)
    patch path, params: { action_name: "assign", command_id: "bad", version: 0 }
    expect(response).to have_http_status(:bad_request)
  end

  it "denies cross-owner reads and commands" do
    other = create(:admin_user).handoff_items.create!(title: "Other checklist")
    get admin_work_handoff_path(item: other.public_id)
    expect(response).to have_http_status(:not_found)
    sign_in admin_user
    patch admin_handoff_item_path(other.public_id), params: { action_name: "assign", command_id: SecureRandom.uuid, version: 0 }
    expect(response).to have_http_status(:not_found)
  end

  it "requires authentication" do
    sign_out admin_user
    post admin_handoff_items_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end
end
