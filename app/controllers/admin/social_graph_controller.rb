# app/controllers/admin/social_graph_controller.rb
# frozen_string_literal: true

module Admin
  class SocialGraphController < ApplicationController
    before_action :authenticate_admin_user!
    def show
      render json: SocialGraph::Explorer.new(admin_user: current_admin_user, root_id: params[:root_id], target_id: params[:target_id], depth: params[:depth] || 1).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :bad_request
    end
  end
end
