# spec/requests/bluebonnet_workspace_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Texas Bluebonnet composition prototype" do
  it "requires the existing administrator authentication" do
    get admin_data_explorer_path, params: { composition: "bluebonnet" }

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "opts in only on the explorer and preserves native routes and fallback" do
    sign_in create(:admin_user)
    get admin_data_explorer_path, params: { composition: "bluebonnet" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-activeadmin-theme="texas-bluebonnet"')
    expect(response.body).to include('class="bluebonnet-workspace"')
    props = JSON.parse(response.parsed_body.at_css('[data-react-component="AccountExplorer"]')["data-react-props"])
    expect(props.fetch("composition")).to eq(
      "dataHeading" => "bluebonnet-data-heading",
      "dataSurface" => "bluebonnet-data-surface",
      "dataTable" => "bluebonnet-data-table",
      "pagination" => "bluebonnet-pagination",
      "primaryAction" => "bluebonnet-primary-action",
      "toolbar" => "bluebonnet-toolbar",
      "toolbarSurface" => "bluebonnet-toolbar-surface"
    )
    expect(response.body).to include('data-react-component="AccountExplorer"')
    expect(response.body).to include('/showcase-icons.svg#heroicons-squares-2x2')
    expect(response.body).to include("Interactive filtering requires JavaScript")
    expect(response.body).to include(admin_accounts_path)
    expect(response.body).to include('data-drawer-show="main-menu"')
    expect(response.body).not_to include('data-react-component="ThemeSwitcher"')

    get admin_data_explorer_path
    expect(response.body).not_to include('data-activeadmin-theme="texas-bluebonnet"')
    expect(response.body).not_to include('class="bluebonnet-workspace"')
    expect(response.body).to include('data-react-component="ThemeSwitcher"')

    get admin_root_path, params: { composition: "bluebonnet" }
    expect(response.body).not_to include('data-activeadmin-theme="texas-bluebonnet"')
    expect(response.body).not_to include('class="bluebonnet-workspace"')
    expect(response.body).to include('data-react-component="ThemeSwitcher"')
  end
end
