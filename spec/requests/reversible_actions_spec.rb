# spec/requests/reversible_actions_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reversible actions" do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:admin_user) }
  let(:account) { create(:account, status: "active", region: "Central") }

  it "uses canonical forms and owner-scoped undo with truthful expiry errors" do
    get admin_reversible_actions_path
    expect(response).to redirect_to(new_admin_user_session_path)
    sign_in admin
    account
    get admin_reversible_actions_path
    expect(response.body).to include("Change a region", "Your change receipts")
    post admin_reversible_actions_change_path, params: { account_id: account.id, region: "East", request_key: SecureRandom.uuid, lock_version: 0 }
    receipt = ReversibleChange.last
    get admin_reversible_actions_path
    expect(response.body).to include("Undo region change", "change: Central")
    post admin_reversible_actions_undo_path, params: { receipt_id: receipt.id }
    expect(account.reload.region).to eq("Central")
    get admin_reversible_actions_path
    expect(response.body).to include("already undone", "undo: East")
    post admin_reversible_actions_change_path, params: { account_id: account.id, region: "East", request_key: SecureRandom.uuid, lock_version: 0 }
    expect(flash[:alert]).to include("Account changed")
    post admin_reversible_actions_change_path, params: { account_id: account.id, region: "East", request_key: SecureRandom.uuid, lock_version: account.lock_version }
    expired = ReversibleChange.last
    travel_to(expired.expires_at + 1.second) do
      post admin_reversible_actions_undo_path, params: { receipt_id: expired.id }
      expect(flash[:alert]).to include("expired")
    end
    sign_out admin
    sign_in create(:admin_user)
    post admin_reversible_actions_undo_path, params: { receipt_id: expired.id }
    expect(response).to have_http_status(:not_found)
  end
end
