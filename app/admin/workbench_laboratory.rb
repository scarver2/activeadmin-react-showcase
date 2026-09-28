# app/admin/workbench_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Workbench Laboratory" do
  menu parent: "Overview", label: "Workbench 1.3 Laboratory", priority: 30

  content title: "Workbench 1.3 — Heritage Laboratory" do
    requested_status = params[:status].to_s
    status = Account::STATUSES.include?(requested_status) ? requested_status : nil
    accounts = Account.order(:name, :id).limit(8)
    accounts = accounts.where(status: status) if status

    render partial: "admin/workbench_laboratory/desktop", locals: { accounts: accounts.to_a, status: status }
  end
end
