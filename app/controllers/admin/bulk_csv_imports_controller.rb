# app/controllers/admin/csv_imports_controller.rb
# frozen_string_literal: true

module Admin
  class BulkCsvImportsController < ApplicationController
    before_action :authenticate_admin_user!
    before_action :load_import, only: %i[confirm show]

    def create
      csv_import = CsvImports::Create.call(admin_user: current_admin_user, source: params.require(:source))
      respond_to do |format|
        format.html { redirect_to "/admin/csv_import_workflow?token=#{csv_import.token}", notice: "CSV uploaded for review." }
        format.json { render json: CsvImports::Serializer.new(csv_import, include_preview: true).as_json, status: :created }
      end
    rescue ActionController::ParameterMissing, CsvImports::Reader::InvalidFile => e
      respond_to do |format|
        format.html { redirect_to "/admin/csv_import_workflow", alert: e.message }
        format.json { render json: { error: e.message }, status: :unprocessable_content }
      end
    end

    def show
      render json: CsvImports::Serializer.new(@csv_import, include_preview: @csv_import.status == "draft").as_json
    end

    def confirm
      CsvImports::Confirm.call(csv_import: @csv_import, mappings: permitted_mappings)
      respond_to do |format|
        format.html { redirect_to "/admin/csv_import_workflow?token=#{@csv_import.token}", notice: "Import queued." }
        format.json { render json: CsvImports::Serializer.new(@csv_import).as_json }
      end
    rescue ActionController::ParameterMissing, CsvImports::Mapping::InvalidMapping, CsvImports::Confirm::AlreadyConfirmed => e
      respond_to do |format|
        format.html { redirect_to "/admin/csv_import_workflow?token=#{@csv_import.token}", alert: e.message }
        format.json { render json: { error: e.message }, status: :unprocessable_content }
      end
    end

    private

    def load_import
      @csv_import = current_admin_user.csv_imports.find_by!(token: params[:token])
    end

    def permitted_mappings
      headers = CsvImports::Reader.new(@csv_import).rows.headers
      params.require(:mappings).permit(*headers).to_h
    end
  end
end
