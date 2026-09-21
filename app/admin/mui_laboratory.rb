# app/admin/mui_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "MUI Laboratory" do
  menu parent: "Overview", label: "MUI Laboratory", priority: 33,
       url: proc { admin_mui_laboratory_path }

  content title: "MUI — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/mui_laboratory/workspace",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
