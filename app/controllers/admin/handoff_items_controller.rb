# app/controllers/admin/handoff_items_controller.rb
# frozen_string_literal: true

module Admin
  class HandoffItemsController < ApplicationController
    before_action :authenticate_admin_user!

    def create
      item = current_admin_user.handoff_items.create!(title: "Synthetic dispatch checklist")
      redirect_to admin_work_handoff_path(item: item.public_id)
    end

    def update
      item = current_admin_user.handoff_items.find_by!(public_id: params[:public_id])
      Handoffs::Transition.call(item:, admin_user: current_admin_user, action: params[:action_name],
                               command_id: params[:command_id], version: params[:version])
      redirect_to admin_work_handoff_path(item: item.public_id), notice: "Work state saved."
    rescue Handoffs::Transition::Conflict => error
      render html: helpers.safe_join([
        helpers.content_tag(:p, error.message),
        helpers.link_to("Refresh work state", admin_work_handoff_path(item: item.public_id))
      ]), status: :conflict
    rescue ArgumentError
      head :bad_request
    end
  end
end
