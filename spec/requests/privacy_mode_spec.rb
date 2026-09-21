# spec/requests/privacy_mode_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard Privacy Mode" do
  let(:admin) { create(:admin_user) }

  def privacy_props
    get admin_root_path
    node = response.parsed_body.at_css('[data-react-component="PrivacyMode"]')
    JSON.parse(node["data-react-props"])
  end

  it "requires authentication" do
    patch admin_privacy_mode_path, params: { enabled: false }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "defaults on and persists explicit booleans only in the current administrator session" do
    sign_in admin
    expect(privacy_props.fetch("initialEnabled")).to be(true)

    patch admin_privacy_mode_path, params: { enabled: false }, as: :json
    expect(response.parsed_body).to eq("enabled" => false)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(privacy_props.fetch("initialEnabled")).to be(false)

    patch admin_privacy_mode_path, params: { enabled: "false-ish" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(privacy_props.fetch("initialEnabled")).to be(false)

    sign_out admin
    sign_in create(:admin_user)
    expect(privacy_props.fetch("initialEnabled")).to be(true)
  end

  it "supports the ordinary HTML fallback" do
    sign_in admin
    patch admin_privacy_mode_path, params: { enabled: "true" }
    expect(response).to redirect_to(admin_root_path)
    expect(privacy_props.fetch("initialEnabled")).to be(true)
  end
end
