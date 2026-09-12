# spec/requests/admin/activity_notifications_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin activity notifications" do
  let(:admin_user) { create(:admin_user) }

  it "requires authentication" do
    get admin_activity_center_notifications_path, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "scopes history and updates to the authenticated owner" do
    own = create(:activity_notification, admin_user:)
    other = create(:activity_notification)
    sign_in admin_user
    get admin_activity_center_notifications_path, as: :json
    expect(response.parsed_body.pluck("id")).to eq([ own.id ])

    patch admin_activity_center_notification_path(other), params: { read: true }, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "creates live activity and persists read state" do
    sign_in admin_user
    post admin_activity_center_notifications_path, as: :json
    expect(response).to have_http_status(:created)
    patch admin_activity_center_notification_path(response.parsed_body.fetch("id")), params: { read: true }, as: :json
    expect(response.parsed_body.fetch("read")).to be(true)
  end

  it "supports HTML creation" do
    sign_in admin_user
    post admin_activity_center_notifications_path
    expect(response).to redirect_to("/admin/activity_center")
  end
end
