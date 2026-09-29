# app/controllers/admin/conversation_read_states_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationReadStatesController < ConversationBaseController
    before_action :load_message

    def create
      @membership.mark_read_through!(@message)
      redirect_to admin_conversation_path(@conversation.public_id), notice: "Read position updated."
    end

    def destroy
      @membership.mark_unread_from!(@message)
      redirect_to admin_conversation_path(@conversation.public_id), notice: "Unread position updated."
    end
  end
end
