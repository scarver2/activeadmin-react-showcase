# spec/requests/showcase_dashboard_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Showcase dashboard" do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  it "renders the server-owned React mount contract for an authenticated admin" do
    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-react-component="FoundationStatus"')
    expect(response.body).to include("Showcase metrics remain available from the server")
  end

  it "renders the architecture reference" do
    get admin_architecture_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Single-host foundation")
  end

  it "renders the read-only account index" do
    create(:account)

    get admin_accounts_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Demo Account")
  end

  it "renders administrator index and form surfaces" do
    get admin_admin_users_path
    expect(response).to have_http_status(:ok)

    get new_admin_admin_user_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Password confirmation")
  end
end
