# app/admin/amigaos_4_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "AmigaOS 4 Laboratory" do
  menu parent: "Overview", label: "AmigaOS 4 Laboratory", priority: 34,
       url: proc { admin_amigaos_4_laboratory_path }

  content title: "AmigaOS 4 — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/amigaos_4_laboratory/workspace",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
