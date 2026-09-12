# spec/requests/admin/message_preview_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin message preview center" do
  it "requires authentication and exposes only the non-production preview" do
    get admin_message_preview_center_path
    expect(response).to redirect_to(new_admin_user_session_path)
    sign_in create(:admin_user)
    MessagePreview::Seed.call
    get admin_message_preview_center_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Development Message &amp; Document Preview")
  end
end
