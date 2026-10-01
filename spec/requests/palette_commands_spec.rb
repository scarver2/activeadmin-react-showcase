# spec/requests/palette_commands_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Palette commands and recent context" do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  # Keep records committed across the rejected request and subsequent confirmations.
  # Request exception cleanup must not discard the test's outer transaction.
  it "executes two domain categories only after explicit owner-scoped confirmation", database_cleaner: :truncation do
    operation = create(:operation, admin_user: admin)
    notification = ActivityCenter::CreateWorkflowReview.call(admin_user: admin)
    get "/admin/global-search", params: { query: "cancel" }
    expect(response.parsed_body.fetch("results")).to include(include("id" => "cancel:#{operation.id}", "group" => "Permitted commands"))
    get admin_command_palette_path(command: "cancel:#{operation.id}")
    expect(response.body).to include("Confirm command", "Cancel without changes")
    expect(operation.reload.state).to eq("queued")
    post admin_command_palette_execute_path, params: { command: "cancel:#{operation.id}" }
    expect(response).to have_http_status(:bad_request)
    expect(operation.reload.state).to eq("queued")
    post admin_command_palette_execute_path, params: { command: "cancel:#{operation.id}", confirmed: "yes" }
    expect(operation.reload.state).to eq("cancelled")
    post admin_command_palette_execute_path, params: { command: "dismiss:#{notification.id}", confirmed: "yes" }
    expect(notification.reload.dismissed_at).to be_present
    post admin_command_palette_execute_path, params: { command: "cancel:#{operation.id}", confirmed: "yes" }
    expect(response).to redirect_to(admin_command_palette_path)
    other = create(:operation)
    post admin_command_palette_execute_path, params: { command: "cancel:#{other.id}", confirmed: "yes" }
    expect(other.reload.state).to eq("queued")
    get admin_command_palette_path(command: "unknown:1")
    expect(response.body).to include("no longer available")
  end

  it "records bounded session-local references and resolves only canonical authorized targets" do
    account = create(:account)
    get admin_palette_visit_path(kind: "Account", id: account.id)
    expect(response).to redirect_to(admin_account_path(account))
    get "/admin/global-search"
    expect(response.parsed_body.fetch("results")).to include(include("kind" => "Recent", "label" => account.name))
    get admin_command_palette_path
    expect(response.body).to include("Recent: #{account.name}")
    get admin_palette_visit_path(kind: "Page", id: "https://evil.example")
    expect(response).to have_http_status(:not_found)
    get admin_palette_visit_path(kind: "Secret", id: account.id)
    expect(response).to have_http_status(:not_found)
    article = create(:showcase_article)
    get admin_palette_visit_path(kind: "Article", id: article.id)
    expect(response).to redirect_to(admin_showcase_article_path(article))
    get admin_palette_visit_path(kind: "Page", id: "/admin/calendar_scheduler")
    expect(response).to redirect_to("/admin/calendar_scheduler")
    article.destroy!
    get "/admin/global-search"
    expect(response).to have_http_status(:ok)
    sign_out admin
    sign_in create(:admin_user)
    get "/admin/global-search"
    expect(response.parsed_body.fetch("results")).to be_empty
  end
end
