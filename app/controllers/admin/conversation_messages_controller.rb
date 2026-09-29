# app/controllers/admin/conversation_messages_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationMessagesController < ConversationBaseController
    before_action :load_authored_message, only: %i[destroy edit update]

    def index
      page = Conversations::MessagePage.call(conversation: @conversation, before: params[:before])
      inbox_entries = Conversations::Inbox.call(admin_user: current_admin_user)
      render json: Conversations::WorkspaceSerializer.call(inbox_entries:, membership: @membership, message_page: page)
    end

    def create
      message = Conversations::CreateMessage.call(
        body: message_params.fetch(:body),
        conversation: @conversation,
        membership: @membership
      )
      mutation_response(message:, notice: "Message sent.", status: :created)
    rescue ActiveRecord::RecordInvalid => error
      invalid_response(error)
    end

    def edit
      raise ActiveRecord::RecordNotFound unless @message.editable_by?(@membership)
    end

    def update
      message = Conversations::EditMessage.call(
        body: message_params.fetch(:body),
        membership: @membership,
        message: @message
      )
      mutation_response(message:, notice: "Message updated.")
    rescue Conversations::EditMessage::EditWindowClosed
      raise ActiveRecord::RecordNotFound
    rescue ActiveRecord::RecordInvalid => error
      invalid_response(error)
    end

    def destroy
      message = Conversations::WithdrawMessage.call(message: @message, membership: @membership)
      mutation_response(message:, notice: "Message withdrawn.")
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

    def invalid_response(error)
      respond_to do |format|
        format.html do
          redirect_to admin_conversation_path(@conversation.public_id), alert: error.record.errors.full_messages.to_sentence
        end
        format.json { render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content }
      end
    end

    def mutation_response(message:, notice:, status: :ok)
      respond_to do |format|
        format.html { redirect_to admin_conversation_path(@conversation.public_id), notice: }
        format.json do
          render json: {
            message: Conversations::WorkspaceSerializer.message(message:, membership: @membership),
            ok: true
          }, status:
        end
      end
    end
  end
end
