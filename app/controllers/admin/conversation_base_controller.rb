# app/controllers/admin/conversation_base_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationBaseController < ActiveAdmin::BaseController
    before_action :authenticate_admin_user!
    before_action :ensure_conversations_enabled
    before_action :load_membership

    private

    def active_admin_config
      ActiveAdmin.application.namespace(:admin).resource_for(Conversation)
    end

    def ensure_conversations_enabled
      raise ActiveRecord::RecordNotFound unless Conversations::Availability.enabled?
    end

    def load_membership
      @membership = current_admin_user.conversation_memberships
                                      .includes(:conversation)
                                      .joins(:conversation)
                                      .find_by!(chat_rooms: { public_id: params[:conversation_public_id] || params[:public_id] })
      @conversation = @membership.conversation
    end

    def load_message
      @message = @conversation.messages.find_by!(public_id: params[:message_public_id])
    end
  end
end
