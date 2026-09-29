# app/admin/mercury_flight_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Mercury Flight Laboratory" do
  menu parent: "Overview", label: "Mercury Flight Laboratory", priority: 38,
       url: proc { admin_mercury_flight_laboratory_path }

  content title: "Mercury Flight — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/mercury_flight_laboratory/workspace",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
