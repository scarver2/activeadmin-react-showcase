# spec/requests/bulk_action_workbench_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bulk action workbench" do
  let(:admin) { create(:admin_user) }
  let(:account) { create(:account) }

  it "provides canonical preview, explicit confirmation, status and owner isolation" do
    get admin_bulk_action_workbench_path
    expect(response).to redirect_to(new_admin_user_session_path)
    sign_in admin
    account
    get admin_bulk_action_workbench_path
    expect(response.body).to include("Select accounts", "Preview selected records")
    post admin_bulk_action_workbench_preview_path, params: { account_ids: [ account.id ], region: "East" }
    batch = BulkRegionBatch.last
    get admin_bulk_action_workbench_path(batch: batch.id)
    expect(response.body).to include("eligible", "Confirm region changes")
    post admin_bulk_action_workbench_confirm_path, params: { batch_id: batch.id }
    expect(response).to have_http_status(:bad_request)
    expect(batch.reload.state).to eq("preview")
    post admin_bulk_action_workbench_confirm_path, params: { batch_id: batch.id, confirmed: "yes" }
    BulkRegionJob.perform_now(batch.id)
    get admin_bulk_action_workbench_status_path(batch_id: batch.id)
    expect(response.parsed_body).to include("state" => "completed", "progress" => 100)
    get admin_bulk_action_workbench_path(batch: batch.id)
    expect(response.body).to include("updated", "Refresh canonical results")
    expect(response.body).not_to include("Resume pending records")
    sign_out admin
    other = create(:admin_user)
    sign_in other
    get admin_bulk_action_workbench_status_path(batch_id: batch.id)
    expect(response).to have_http_status(:not_found)
    sign_in other
    post admin_bulk_action_workbench_confirm_path, params: { batch_id: batch.id, confirmed: "yes" }
    expect(response).to have_http_status(:not_found)
    sign_in other
    post admin_bulk_action_workbench_preview_path, params: { region: "East" }
    expect(flash[:alert]).to include("Select between")
  end
end
