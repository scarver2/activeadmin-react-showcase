# spec/requests/theme_studio_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Theme Studio" do
  let(:admin) { create(:admin_user) }

  it "requires an authenticated administrator" do
    get admin_theme_studio_path

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "renders the bounded editor contract and useful no-JavaScript fallback" do
    sign_in admin

    get admin_theme_studio_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css('[data-react-component="ThemeStudio"]').size).to eq(1)
    expect(response.body).to include(
      "ActiveAdmin V3 baseline",
      "JavaScript is optional",
      "interactive edits are reversible preview state only"
    )
  end
end
