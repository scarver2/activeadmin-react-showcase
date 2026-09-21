# spec/requests/bluebonnet_workspace_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Texas Bluebonnet composition prototype" do
  it "requires the existing administrator authentication" do
    get admin_data_explorer_path, params: { composition: "bluebonnet" }

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "opts in on the operating home and explicit explorer while preserving native routes and fallback" do
    sign_in create(:admin_user)
    get admin_data_explorer_path, params: { composition: "bluebonnet" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="bluebonnet-workspace"')
    expect(response.body).to include('data-react-component="AccountExplorer"')
    expect(response.body).to include('/showcase-icons.svg#heroicons-squares-2x2')
    expect(response.body).to include("Interactive filtering requires JavaScript")
    expect(response.body).to include(admin_accounts_path)
    expect(response.body).to include('data-drawer-show="main-menu"')
    expect(response.body).not_to include('data-react-component="ThemeSwitcher"')

    get admin_data_explorer_path
    expect(response.body).not_to include('class="bluebonnet-workspace"')
    expect(response.body).to include('data-react-component="ThemeSwitcher"')

    get admin_root_path, params: { composition: "bluebonnet" }
    expect(response.body).to include('data-react-component="MasterDashboard"', "Texas Bluebonnet")
    expect(response.body).not_to include('data-react-component="ThemeSwitcher"')
  end
end
