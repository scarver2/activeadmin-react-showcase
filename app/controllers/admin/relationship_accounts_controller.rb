# app/controllers/admin/relationship_accounts_controller.rb
# frozen_string_literal: true

module Admin
  class RelationshipAccountsController < ApplicationController
    before_action :require_admin_user

    def show
      render json: Showcase::RelationshipExplorer.new(**explorer_params).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def explorer_params
      params.permit(:plan, :query, :region, :relationship_role, :selected_id).to_h.symbolize_keys
    end

    def require_admin_user
      head :unauthorized unless admin_user_signed_in?
    end
  end
end
