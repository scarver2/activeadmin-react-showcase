# app/controllers/admin/conversation_dispositions_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationDispositionsController < ConversationBaseController
    before_action :load_message

    def update
      kind = request.delete? ? nil : disposition_params.fetch(:kind)
      Conversations::SetDisposition.call(message: @message, membership: @membership, kind:)
      notice = kind ? "#{kind.capitalize} disposition selected." : "Disposition removed."
      respond_to do |format|
        format.html { redirect_to conversation_location, notice: }
        format.json do
          render json: {
            message: Conversations::WorkspaceSerializer.message(message: @message.reload, membership: @membership),
            ok: true
          }
        end
      end
    rescue ArgumentError
      respond_to do |format|
        format.html { redirect_to conversation_location, alert: "Choose Like, Dislike, or Question." }
        format.json { render json: { error: "Choose Like, Dislike, or Question." }, status: :unprocessable_content }
      end
    rescue Conversations::SetDisposition::NotAuthorized
      raise ActiveRecord::RecordNotFound
    end

    private

    def conversation_location
      admin_conversation_path(
        @conversation.public_id,
        anchor: "message-#{@message.public_id}",
        before: @message.sequence + 1
      )
    end

    def disposition_params
      params.expect(disposition: [ :kind ])
    end
  end
end
