# app/controllers/admin/content_builder_documents_controller.rb
# frozen_string_literal: true

module Admin
  class ContentBuilderDocumentsController < ApplicationController
    before_action :authenticate_admin_user!
    def update
      document = current_admin_user.content_documents.find(params[:id])
      blocks = params.require(:blocks).map(&:to_unsafe_h)
      saved = ContentBuilder::Save.call(document:, blocks:, expected_lock_version: params[:lock_version])
      render json: { document: ContentBuilder::Serializer.new(saved).as_json }
    rescue ActionController::ParameterMissing, ArgumentError, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_content
    rescue ActiveRecord::StaleObjectError
      render json: { error: "The document changed; reload before saving" }, status: :conflict
    end
  end
end
