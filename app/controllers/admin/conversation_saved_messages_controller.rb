# app/controllers/admin/conversation_saved_messages_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationSavedMessagesController < ConversationBaseController
    before_action :load_message

    def update
      saved = request.post?
      Conversations::SetSavedState.call(message: @message, membership: @membership, saved:)
      notice = saved ? "Message saved." : "Message removed from saved messages."
      respond_to do |format|
        format.html { redirect_to conversation_location, notice: }
        format.json do
          render json: {
            message: Conversations::WorkspaceSerializer.message(message: @message, membership: @membership),
            ok: true
          }
        end
      end
    rescue Conversations::SetSavedState::NotAuthorized
      raise ActiveRecord::RecordNotFound
    end

    private

    def conversation_location
      admin_conversation_path(@conversation.public_id, anchor: "message-#{@message.public_id}")
    end
  end
end
