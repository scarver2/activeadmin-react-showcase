# spec/requests/admin/activity_notifications_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin activity notifications" do
  let(:admin_user) { create(:admin_user) }

  def create_notification(admin_user:)
    ActivityCenter::Create.call(
      admin_user:,
      attributes: {
        body: "Account needs review",
        deep_link: "/admin/accounts",
        kind: "account",
        occurred_at: Time.current,
        subject: "Account review"
      },
      enqueue_delivery: false
    )
  end

  it "requires authentication" do
    get admin_activity_center_notifications_path, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "scopes history and updates to the authenticated owner" do
    own = create_notification(admin_user:)
    other = create_notification(admin_user: create(:admin_user))
    sign_in admin_user
    get admin_activity_center_notifications_path, as: :json
    expect(response.parsed_body.pluck("id")).to eq([ own.id ])

    patch admin_activity_center_notification_path(other), params: { read: true }, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "creates live activity and persists read state" do
    allow(ActivityCenter::UnreadProjection).to receive(:broadcast)
    sign_in admin_user
    post admin_activity_center_notifications_path, as: :json
    expect(response).to have_http_status(:created)
    patch admin_activity_center_notification_path(response.parsed_body.fetch("id")), params: { read: true }, as: :json
    expect(response.parsed_body.fetch("read")).to be(true)
    expect(ActivityCenter::UnreadProjection).to have_received(:broadcast).with(admin_user)
  end

  it "supports HTML creation" do
    sign_in admin_user
    post admin_activity_center_notifications_path
    expect(response).to redirect_to("/admin/activity_center")
  end

  it "supports durable read state without JavaScript" do
    notification = create_notification(admin_user:)
    sign_in admin_user

    patch admin_activity_center_notification_path(notification), params: { read: true }

    expect(response).to redirect_to("/admin/activity_center")
    expect(notification.reload).to be_read
  end

  it "renders a server fallback link inside the header notification mount" do
    create_notification(admin_user:)
    sign_in admin_user
    get "/admin"

    expect(response.body).to include('data-react-component="NotificationBell"')
    expect(response.body).to include('href="/admin/activity_center"')
    expect(response.body).to include("Activity Center")
  end

  it "does not seed notifications while rendering the activity center" do
    sign_in admin_user

    expect { get "/admin/activity_center" }.not_to change(Noticed::Notification, :count)
    expect(response).to have_http_status(:ok)
  end
end
