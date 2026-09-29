# app/admin/aros_zune_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "AROS Zune Laboratory" do
  menu parent: "Overview", label: "AROS/Zune Laboratory", priority: 35,
       url: proc { admin_aros_zune_laboratory_path }

  content title: "AROS/Zune — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/aros_zune_laboratory/workspace",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
