# spec/requests/activity_timeline_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cross-domain activity timeline" do
  let(:admin) { create(:admin_user) }

  it "authenticates both timeline and canonical fixture source requests" do
    get admin_activity_timeline_path
    expect(response).to redirect_to(new_admin_user_session_path)
    get admin_activity_timeline_path(source: "comment-0000")
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "renders the enhanced contract and a bounded, navigable no-JavaScript timeline" do
    sign_in admin
    get admin_activity_timeline_path(family: "comment", group: "family")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cross-Domain Activity Timeline", "Synthetic laboratory", "Comments", "Older events")
    expect(response.parsed_body.css('[data-react-component="ActivityTimeline"]').size).to eq(1)
    expect(response.body).to include("Source redacted", "Source deleted")
    expect(response.body).not_to include("comment-0003")
  end

  it "shows domain-owned source fields only when the source policy allows it", database_cleaner: :truncation do
    sign_in admin
    get admin_activity_timeline_path(source: "comment-0000")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Use the reusable packing crates.", "Back to timeline")
    %w[comment-0001 comment-0002 comment-0003 unknown-0000].each do |source|
      get admin_activity_timeline_path(source:)
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Use the reusable packing crates.")
    end
  end

  it "gives accessible recovery for invalid filters and resume links" do
    sign_in admin
    get admin_activity_timeline_path(cursor: "invalid")
    expect(response.body).to include('role="alert"', "Start again")
    get admin_activity_timeline_path(family: "unsupported")
    expect(response.body).to include("Unknown event family")
  end
end
