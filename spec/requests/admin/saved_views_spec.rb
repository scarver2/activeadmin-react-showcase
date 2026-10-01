# spec/requests/admin/saved_views_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Personal saved workspaces" do
  let(:admin) { create(:admin_user) }
  let(:definition) { SavedView::DEFAULT_DEFINITION.deep_dup }
  let(:view) { admin.saved_views.create!(name: "Personal accounts", definition:) }

  it "requires login and prevents cross-owner reads and mutations" do
    get admin_saved_views_path
    expect(response).to redirect_to(new_admin_user_session_path)
    sign_in create(:admin_user)
    get admin_saved_view_path(view)
    expect(response).to have_http_status(:not_found)
    patch admin_saved_view_path(view), params: { saved_view: { name: "Stolen" } }
    expect(response).to have_http_status(:not_found)
    post duplicate_admin_saved_view_path(view)
    expect(response).to have_http_status(:not_found)
    post make_default_admin_saved_view_path(view)
    expect(response).to have_http_status(:not_found)
    delete admin_saved_view_path(view)
    expect(response).to have_http_status(:not_found)
  end

  it "creates, edits, duplicates, favorites, selects default and deletes through canonical Rails forms" do
    sign_in admin
    get default_workspace_admin_saved_views_path
    expect(response).to redirect_to(admin_saved_views_path)
    get new_admin_saved_view_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("SavedViewEditor", "Account view definition")
    post admin_saved_views_path, params: { saved_view: { name: "Daily work", definition:, admin_user_id: create(:admin_user).id } }
    expect(response).to have_http_status(:redirect)
    saved = admin.saved_views.find_by!(name: "Daily work")
    patch admin_saved_view_path(saved), params: { saved_view: { name: "Renamed", favorite: "1", lock_version: saved.lock_version } }
    expect(saved.reload.name).to eq("Renamed")
    expect(saved).to be_favorite
    post make_default_admin_saved_view_path(saved)
    expect(saved.reload).to be_default_view
    get default_workspace_admin_saved_views_path
    expect(response).to redirect_to(admin_saved_view_path(saved))
    expect { post duplicate_admin_saved_view_path(saved) }.to change(admin.saved_views, :count).by(1)
    copy = admin.saved_views.order(:id).last
    expect(copy.definition).to eq(saved.definition)
    expect(copy).not_to be_default_view
    expect { delete admin_saved_view_path(copy) }.to change(admin.saved_views, :count).by(-1)
    patch admin_saved_view_path(saved), params: { saved_view: { name: "Stale", lock_version: 0 } }
    expect(response).to redirect_to(edit_admin_saved_view_path(saved))
    expect(saved.reload.name).to eq("Renamed")
  end

  it "renders filtered grouped data, pagination, empty and stale-definition recovery" do
    sign_in admin
    6.times { |index| create(:account, name: "Workspace #{index}") }
    view.update!(definition: definition.merge("query" => "Workspace", "group" => "plan"))
    get admin_saved_view_path(view)
    expect(response.body).to include("6 accounts", "Next", "Workspace 0")
    get admin_saved_view_path(view, page: 2)
    expect(response.body).to include("Previous", "Workspace 5")
    view.update!(definition: definition.merge("query" => "unmatched"))
    get admin_saved_view_path(view)
    expect(response.body).to include("No accounts match")
    view.update_columns(definition: { "schema" => 99 })
    get admin_saved_view_path(view)
    expect(response.body).to include("Repair view definition")
    get edit_admin_saved_view_path(view)
    expect(response).to have_http_status(:ok)
    patch admin_saved_view_path(view), params: { saved_view: { definition: definition.merge("sort" => "secret") } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
