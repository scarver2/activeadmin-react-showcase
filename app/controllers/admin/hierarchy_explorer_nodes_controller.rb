# app/controllers/admin/hierarchy_explorer_nodes_controller.rb
# frozen_string_literal: true

module Admin
  class HierarchyExplorerNodesController < ApplicationController
    before_action :authenticate_admin_user!

    def index
      render json: Hierarchy::Query.new(admin_user: current_admin_user, parent_id: params[:parent_id]).as_json
    end

    def update
      node = current_admin_user.hierarchy_nodes.find(params[:id])
      Hierarchy::Reparent.call(
        admin_user: current_admin_user,
        expected_lock_version: params[:lock_version],
        node:,
        parent_id: params[:parent_id],
        position: params.fetch(:position, 0)
      )
      render json: { node: Hierarchy::Serializer.new(node).as_json }
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    rescue Hierarchy::Reparent::StaleWrite => error
      render json: { error: error.message }, status: :conflict
    end
  end
end
