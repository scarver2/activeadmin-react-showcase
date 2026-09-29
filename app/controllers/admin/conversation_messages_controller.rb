# app/controllers/admin/conversation_messages_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationMessagesController < ConversationBaseController
    before_action :load_authored_message, only: %i[destroy edit update]

    def create
      Conversations::CreateMessage.call(
        body: message_params.fetch(:body),
        conversation: @conversation,
        membership: @membership
      )
      redirect_to admin_conversation_path(@conversation.public_id), notice: "Message sent."
    rescue ActiveRecord::RecordInvalid => error
      redirect_to admin_conversation_path(@conversation.public_id), alert: error.record.errors.full_messages.to_sentence
    end

    def edit
      raise ActiveRecord::RecordNotFound unless @message.editable_by?(@membership)
    end

    def update
      Conversations::EditMessage.call(
        body: message_params.fetch(:body),
        membership: @membership,
        message: @message
      )
      redirect_to admin_conversation_path(@conversation.public_id), notice: "Message updated."
    rescue Conversations::EditMessage::EditWindowClosed
      raise ActiveRecord::RecordNotFound
    rescue ActiveRecord::RecordInvalid => error
      redirect_to admin_conversation_path(@conversation.public_id), alert: error.record.errors.full_messages.to_sentence
    end

    def destroy
      Conversations::WithdrawMessage.call(message: @message, membership: @membership)
      redirect_to admin_conversation_path(@conversation.public_id), notice: "Message withdrawn."
    rescue Conversations::WithdrawMessage::WithdrawalNotAllowed
      raise ActiveRecord::RecordNotFound
    end

    private

    def load_authored_message
      @message = @membership.messages.find_by!(public_id: params[:message_public_id])
    end

    def message_params
      params.expect(message: [ :body ])
    end
  end
end
