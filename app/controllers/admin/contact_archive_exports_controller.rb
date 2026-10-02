# app/controllers/admin/contact_archive_exports_controller.rb
# frozen_string_literal: true

module Admin
  class ContactArchiveExportsController < ApplicationController
    before_action :authenticate_admin_user!

    def show
      export = ContactArchives::SyntheticInspector.new.export(params[:format_name])
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["X-Content-Type-Options"] = "nosniff"
      send_data export.fetch(:body), type: export.fetch(:content_type),
                filename: export.fetch(:filename), disposition: "attachment"
    rescue KeyError
      head :not_found
    end
  end
end
