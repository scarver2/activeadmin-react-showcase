# app/admin/conversations.rb
# frozen_string_literal: true

if Conversations::Availability.enabled?
  ActiveAdmin.register Conversation do
    menu label: "Conversations",
         parent: "Collaboration",
         priority: 0,
         if: proc { Conversations::Availability.enabled? }

    actions :index, :show
    config.batch_actions = false
    config.filters = false

    controller do
      before_action :ensure_conversations_enabled

      def index
        @memberships = Conversations::Inbox.call(admin_user: current_admin_user)
      end

      def show
        load_membership
        page = Conversations::MessagePage.call(conversation: @conversation, before: params[:before])
        @messages = page.messages.map do |message|
          Conversations::MessagePresenter.new(message, viewer_membership: @membership)
        end
        @older_cursor = page.older_cursor
      end

      private

      def ensure_conversations_enabled
        raise ActiveRecord::RecordNotFound unless Conversations::Availability.enabled?
      end

      def load_membership
        @membership = current_admin_user.conversation_memberships
                                        .includes(:conversation)
                                        .joins(:conversation)
                                        .find_by!(chat_rooms: { public_id: params[:id] })
        @conversation = @membership.conversation
      end
    end
  end
end
