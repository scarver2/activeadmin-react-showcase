# app/channels/conversation_channel.rb
# frozen_string_literal: true

class ConversationChannel < ApplicationCable::Channel
  def reconcile
    transmit(Conversations::RealtimeChange.snapshot(conversation:))
  end

  private

  attr_reader :conversation

  def subscribed
    membership = current_admin_user.conversation_memberships
                                   .includes(:conversation)
                                   .joins(:conversation)
                                   .find_by(chat_rooms: { public_id: params[:conversation_public_id] })
    return reject unless membership

    @conversation = membership.conversation
    stream_for(conversation)
    transmit(Conversations::RealtimeChange.snapshot(conversation:))
  end
end
