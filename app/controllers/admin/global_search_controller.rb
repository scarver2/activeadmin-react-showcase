# app/controllers/admin/global_search_controller.rb
# frozen_string_literal: true

module Admin
  class GlobalSearchController < ApplicationController
    before_action :require_admin_user

    def show
      render json: Showcase::GlobalSearch.new(admin_user: current_admin_user, query: params[:query]).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def require_admin_user
      head :unauthorized unless admin_user_signed_in?
    end
  end
end
