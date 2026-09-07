# app/controllers/admin/showcase_assets_controller.rb
# frozen_string_literal: true

module Admin
  class ShowcaseAssetsController < ApplicationController
    before_action :authenticate_admin_user!

    def create
      asset = ShowcaseAsset.create!(title: params.require(:title), file: params.require(:file))
      respond_to do |format|
        format.html { redirect_to admin_file_image_manager_path, notice: "Synthetic asset uploaded." }
        format.json { render json: ShowcaseAssets::Serializer.new(asset).as_json, status: :created }
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html { redirect_to admin_file_image_manager_path, alert: e.record.errors.full_messages.to_sentence }
        format.json { render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content }
      end
    end

    def destroy
      asset = ShowcaseAsset.find(params[:id])
      asset.file.purge
      asset.destroy!
      respond_to do |format|
        format.html { redirect_to admin_file_image_manager_path, notice: "Synthetic asset deleted." }
        format.json { head :no_content }
      end
    end
  end
end
