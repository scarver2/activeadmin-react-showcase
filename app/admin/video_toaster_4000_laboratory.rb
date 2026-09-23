# app/admin/video_toaster_4000_laboratory.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Video Toaster 4000 Laboratory" do
  menu parent: "Overview", label: "Video Toaster 4000 Laboratory", priority: 37,
       url: proc { admin_video_toaster_4000_laboratory_path }

  content title: "Video Toaster 4000 / LightWave — Heritage Laboratory" do
    workspace = Showcase::HeritageAccountsWorkspace.new(status: params[:status])

    render partial: "admin/video_toaster_4000_laboratory/workspace",
           locals: { accounts: workspace.accounts, status: workspace.status }
  end
end
