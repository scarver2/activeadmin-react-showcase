# app/controllers/admin/image_editor_annotations_controller.rb
# frozen_string_literal: true

module Admin
  class ImageEditorAnnotationsController < ApplicationController
    before_action :authenticate_admin_user!

    def update
      asset = ShowcaseAsset.find(params[:id])
      annotation = ImageEditor::Save.call(admin_user: current_admin_user, asset:, attributes: annotation_params)
      render json: serialized(annotation)
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    end

    private

    def annotation_params
      params.permit(*ImageEditor::Save::ATTRIBUTES, edit_specification: ImageAnnotation::EDIT_SPECIFICATION_KEYS)
    end

    def serialized(annotation)
      annotation.as_json(only: %i[focal_x focal_y label region_height region_width region_x region_y updated_at]).merge(
        "edit_specification" => annotation.canonical_edit_specification
      )
    end
  end
end
