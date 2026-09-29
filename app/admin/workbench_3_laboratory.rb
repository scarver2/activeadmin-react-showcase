# app/admin/workbench_3_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Workbench 3 Laboratory" do
  menu parent: "Overview", label: "Workbench 3.x Laboratory", priority: 32,
       url: proc { admin_workbench_3_laboratory_path }

  content title: "Workbench 3.x — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/workbench_3_laboratory/desktop",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
