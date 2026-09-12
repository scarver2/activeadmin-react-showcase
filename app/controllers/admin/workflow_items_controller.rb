# app/controllers/admin/workflow_items_controller.rb
# frozen_string_literal: true

module Admin
  class WorkflowItemsController < ApplicationController
    before_action :authenticate_admin_user!

    def move
      item = Workflow::Move.call(
        item: WorkflowItem.find(params[:id]),
        state: params[:state],
        position: params[:position]
      )

      respond_to do |format|
        format.html { redirect_to admin_kanban_workflow_path, notice: "#{item.title} moved." }
        format.json { render json: { items: serialized_items } }
      end
    rescue ActiveRecord::RecordInvalid => error
      respond_to do |format|
        format.html { redirect_to admin_kanban_workflow_path, alert: error.record.errors.full_messages.to_sentence }
        format.json { render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content }
      end
    end

    private

    def serialized_items
      WorkflowItem.ordered.map { |workflow_item| Workflow::Serializer.new(workflow_item).as_json }
    end
  end
end
