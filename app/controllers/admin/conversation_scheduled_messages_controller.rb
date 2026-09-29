# app/controllers/admin/conversation_scheduled_messages_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationScheduledMessagesController < ConversationBaseController
    before_action :load_scheduled_message, only: %i[destroy edit update]
    helper_method :action_items_for_action

    def action_items_for_action
      []
    end

    def index
      @scheduled_messages = owned_scheduled_messages.where(state: %w[pending failed]).chronological.limit(20)
      @recently_delivered = owned_scheduled_messages.includes(:delivered_message).where(state: "delivered")
                                                    .order(delivered_at: :desc, id: :desc)
                                                    .limit(5)
    end

    def create
      scheduled_message = Conversations::ScheduleMessage.call(
        admin_user: current_admin_user,
        body: scheduled_message_params.fetch(:body),
        conversation: @conversation,
        scheduled_for: scheduled_message_params.fetch(:scheduled_for)
      )
      redirect_to scheduled_messages_path, notice: creation_notice(scheduled_message)
    rescue ActiveRecord::RecordInvalid => error
      redirect_to scheduled_messages_path, alert: error.record.errors.full_messages.to_sentence
    rescue Conversations::ScheduleMessage::NotAuthorized
      raise ActiveRecord::RecordNotFound
    end

    def edit
      raise ActiveRecord::RecordNotFound unless @scheduled_message.manageable?
    end

    def update
      Conversations::UpdateScheduledMessage.call(
        admin_user: current_admin_user,
        body: scheduled_message_params.fetch(:body),
        scheduled_for: scheduled_message_params.fetch(:scheduled_for),
        scheduled_message: @scheduled_message
      )
      redirect_to scheduled_messages_path, notice: update_notice(@scheduled_message)
    rescue Conversations::UpdateScheduledMessage::NotManageable
      raise ActiveRecord::RecordNotFound
    rescue ActiveRecord::RecordInvalid => error
      redirect_to scheduled_messages_path, alert: error.record.errors.full_messages.to_sentence
    end

    def destroy
      Conversations::CancelScheduledMessage.call(
        admin_user: current_admin_user,
        scheduled_message: @scheduled_message
      )
      redirect_to scheduled_messages_path, notice: "Scheduled message cancelled."
    rescue Conversations::CancelScheduledMessage::NotCancellable
      raise ActiveRecord::RecordNotFound
    end

    private

    def creation_notice(scheduled_message)
      return "Message scheduled." if scheduled_message.pending?

      "The message was saved, but delivery could not be queued. Edit it to retry."
    end

    def load_scheduled_message
      @scheduled_message = owned_scheduled_messages.find_by!(public_id: params[:scheduled_message_public_id])
    end

    def owned_scheduled_messages
      @conversation.scheduled_messages.where(admin_user: current_admin_user)
    end

    def scheduled_messages_path
      admin_conversation_scheduled_messages_path(@conversation.public_id)
    end

    def update_notice(scheduled_message)
      return "Scheduled message updated." if scheduled_message.pending?

      "The update was saved, but delivery could not be queued. Edit it to retry."
    end

    def scheduled_message_params
      params.expect(scheduled_message: %i[body scheduled_for])
    end
  end
end
