# app/admin/haiku_beta6_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Haiku Beta6 Laboratory" do
  menu parent: "Overview", label: "Haiku beta6 Laboratory", priority: 36,
       url: proc { admin_haiku_beta6_laboratory_path }

  content title: "Haiku beta6 — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/haiku_beta6_laboratory/workspace",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
