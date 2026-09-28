# spec/requests/privacy_view_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Privacy View" do
  let(:admin) { create(:admin_user) }

  def privacy_props
    get admin_root_path
    node = response.parsed_body.at_css('[data-react-component="PrivacyView"]')
    JSON.parse(node["data-react-props"])
  end

  it "requires authentication" do
    patch admin_privacy_view_path, params: { enabled: true }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "defaults off and persists explicit booleans only in the current administrator session" do
    sign_in admin
    expect(privacy_props.fetch("initialEnabled")).to be(false)

    patch admin_privacy_view_path, params: { enabled: true }, as: :json
    expect(response.parsed_body).to eq("enabled" => true)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(privacy_props.fetch("initialEnabled")).to be(true)

    patch admin_privacy_view_path, params: { enabled: "false-ish" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(privacy_props.fetch("initialEnabled")).to be(true)

    sign_out admin
    sign_in create(:admin_user)
    expect(privacy_props.fetch("initialEnabled")).to be(false)
  end

  it "supports the ordinary HTML fallback" do
    sign_in admin
    patch admin_privacy_view_path, params: { enabled: "true" }
    expect(response).to redirect_to(admin_root_path)
    expect(privacy_props.fetch("initialEnabled")).to be(true)
  end
end
