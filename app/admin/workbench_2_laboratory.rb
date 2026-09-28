# app/admin/workbench_2_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Workbench 2 Laboratory" do
  menu parent: "Overview", label: "Workbench 2.x Laboratory", priority: 31,
       url: proc { admin_workbench_2_laboratory_path }

  content title: "Workbench 2.x — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/workbench_2_laboratory/desktop",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
