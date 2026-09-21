# app/admin/workbench_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Workbench Laboratory" do
  menu parent: "Overview", label: "Workbench 1.3 Laboratory", priority: 30

  content title: "Workbench 1.3 — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/workbench_laboratory/desktop",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
