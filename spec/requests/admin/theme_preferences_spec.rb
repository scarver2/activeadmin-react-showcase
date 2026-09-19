# spec/requests/admin/theme_preferences_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin theme preferences" do
  let(:admin_user) { create(:admin_user) }

  it "requires authentication" do
    patch admin_theme_preference_path, params: { theme_preference: "v3_texas" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "persists only the authenticated administrator's supported preference" do
    other = create(:admin_user)
    sign_in admin_user

    patch admin_theme_preference_path, params: { theme_preference: "v3_texas" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("theme" => "v3_texas")
    expect(admin_user.reload.theme_preference).to eq("v3_texas")
    expect(other.reload.theme_preference).to eq("v3")
  end

  it "rejects unsupported preferences without changing durable state" do
    sign_in admin_user

    patch admin_theme_preference_path, params: { theme_preference: "invented" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(admin_user.reload.theme_preference).to eq("v3")
  end

  it "renders an accessible server fallback and supports its HTML update" do
    sign_in admin_user
    get admin_root_path

    expect(response.body).to include('data-react-component="ThemeSwitcher"')
    expect(response.body).to include('data-showcase-theme-marker="v3"')
    expect(response.body).to include("Visual theme")

    patch admin_theme_preference_path, params: { theme_preference: "v3_texas" }
    expect(response).to redirect_to(admin_root_path)
    expect(admin_user.reload.theme_preference).to eq("v3_texas")
  end
end
