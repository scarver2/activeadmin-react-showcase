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
        attachment: message_params[:attachment],
        body: message_params.fetch(:body),
        conversation: @conversation,
        membership: @membership,
        mentioned_memberships:,
        public_id: message_params[:public_id],
        reply_to: reply_to_message
      )
      mutation_response(message:, notice: "Message sent.", status: :created)
    rescue ActiveRecord::RecordInvalid => error
      invalid_response(error)
    rescue Conversations::AttachUpload::InvalidUpload => error
      upload_error_response(error)
    rescue Conversations::CreateMessage::ReplayConflict
      render_replay_conflict
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
      params.expect(message: [ :attachment, :body, :public_id, :reply_to_public_id, { mentioned_member_keys: [] } ])
    end

    def mentioned_memberships
      keys = Array(message_params[:mentioned_member_keys]).compact_blank.uniq
      return [] if keys.empty?

      memberships = @conversation.memberships.where(key: keys).index_by(&:key)
      raise ActiveRecord::RecordNotFound unless memberships.size == keys.size

      keys.map { |key| memberships.fetch(key) }
    end

    def reply_to_message
      public_id = message_params[:reply_to_public_id]
      return if public_id.blank?

      @conversation.messages.find_by!(public_id:)
    end

    def invalid_response(error)
      respond_to do |format|
        format.html do
          redirect_to admin_conversation_path(@conversation.public_id), alert: error.record.errors.full_messages.to_sentence
        end
        format.json { render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content }
      end
    end

    def upload_error_response(error)
      respond_to do |format|
        format.html { redirect_to admin_conversation_path(@conversation.public_id), alert: error.message }
        format.json { render json: { error: error.message }, status: :unprocessable_content }
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

    def render_replay_conflict
      respond_to do |format|
        format.html do
          redirect_to admin_conversation_path(@conversation.public_id),
                      alert: "That send identity was already used for different message content."
        end
        format.json do
          render json: { error: "That send identity was already used for different message content." },
                 status: :conflict
        end
      end
    end
  end
end
