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
        @conversation_workspace = Conversations::WorkspaceSerializer.call(inbox_entries: @memberships)
        render json: @conversation_workspace if request.format.json?
      end

      def show
        load_membership
        page = Conversations::MessagePage.call(conversation: @conversation, before: params[:before])
        @messages = page.messages.map do |message|
          Conversations::MessagePresenter.new(message, viewer_membership: @membership)
        end
        @older_cursor = page.older_cursor
        @memberships = Conversations::Inbox.call(admin_user: current_admin_user)
        @conversation_workspace = Conversations::WorkspaceSerializer.call(inbox_entries: @memberships,
                                                                           membership: @membership,
                                                                           message_page: page)
        @saved_message_ids = @membership.saved_messages.where(message_id: page.messages).pluck(:message_id).to_set
      end

      def search
        @search = Conversations::Search.call(admin_user: current_admin_user, query: params[:q])

        render json: Conversations::SearchSerializer.call(result: @search) if request.format.json?
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

    collection_action :saved, method: :get do
      raise ActiveRecord::RecordNotFound unless Conversations::Availability.enabled?

      @saved_page = Conversations::SavedMessages.call(
        admin_user: current_admin_user,
        after: params[:after],
        before: params[:before]
      )
    end
  end
end
