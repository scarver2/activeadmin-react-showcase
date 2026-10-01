# app/controllers/admin/global_search_controller.rb
# frozen_string_literal: true

module Admin
  class GlobalSearchController < ApplicationController
    before_action :require_admin_user

    def show
      render json: Showcase::PaletteSearch.new(admin_user: current_admin_user, query: params[:query], recent: recent_context).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    def visit
      reference = { "kind" => params[:kind].to_s, "id" => params[:id].to_s }
      item = Showcase::PaletteSearch.new(admin_user: current_admin_user).resolve(reference.fetch("kind"), reference.fetch("id"))
      session[:palette_recent] = ([ reference ] + recent_context.reject { |entry| entry == reference }).first(5)
      session[:palette_recent_owner] = current_admin_user.id
      redirect_to item.fetch(:url)
    end

    private

    def recent_context
      session[:palette_recent_owner] == current_admin_user.id ? Array(session[:palette_recent]) : []
    end

    def require_admin_user
      head :unauthorized unless admin_user_signed_in?
    end
  end
end
