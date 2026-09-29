# app/controllers/admin/conversation_read_states_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationReadStatesController < ConversationBaseController
    before_action :load_message

    def create
      Conversations::SetReadState.call(membership: @membership, message: @message, state: :read_through)
      mutation_response("Read position updated.")
    end

    def destroy
      Conversations::SetReadState.call(membership: @membership, message: @message, state: :unread_from)
      mutation_response("Unread position updated.")
    end

    private

    def mutation_response(notice)
      respond_to do |format|
        format.html { redirect_to admin_conversation_path(@conversation.public_id), notice: }
        format.json { render json: { ok: true } }
      end
    end
  end
end
