# app/channels/conversation_presence_channel.rb
# frozen_string_literal: true

class ConversationPresenceChannel < ApplicationCable::Channel
  SESSION_ID_PATTERN = /\A[a-zA-Z0-9_-]{16,80}\z/

  periodically :expire_stale_presence, every: 2.seconds

  class << self
    attr_writer :registry

    def registry
      @registry ||= Conversations::PresenceRegistry.new
    end
  end

  def heartbeat
    publish(self.class.registry.heartbeat(conversation_id:, session_id:, membership:))
  end

  def reconcile
    transmit(envelope(self.class.registry.snapshot(conversation_id:)))
  end

  def typing(data)
    active = data["active"]
    return unless active == true || active == false

    publish(self.class.registry.typing(conversation_id:, session_id:, active:))
  end

  private

  attr_reader :conversation, :conversation_id, :membership, :session_id

  def subscribed
    @membership = current_admin_user.conversation_memberships
                                    .includes(:conversation)
                                    .joins(:conversation)
                                    .find_by(chat_rooms: { public_id: params[:conversation_public_id] })
    @session_id = params[:session_id].to_s
    return reject unless membership && SESSION_ID_PATTERN.match?(session_id)

    @conversation = membership.conversation
    @conversation_id = conversation.id
    stream_for(conversation)
    publish(self.class.registry.join(conversation_id:, session_id:, membership:))
  end

  def unsubscribed
    return unless conversation_id && session_id

    publish(self.class.registry.leave(conversation_id:, session_id:))
  end

  def expire_stale_presence
    return unless conversation_id

    publish(self.class.registry.expire(conversation_id:))
  end

  def envelope(snapshot)
    {
      conversationPublicId: conversation.public_id,
      kind: "presence",
      online: snapshot.fetch(:online),
      serverAt: Time.current.iso8601(6),
      typing: snapshot.fetch(:typing)
    }
  end

  def publish(transition)
    return unless transition.changed

    self.class.broadcast_to(conversation, envelope(transition.snapshot))
  rescue StandardError => error
    Rails.logger.warn("Conversation presence broadcast failed: #{error.class}: #{error.message}")
  end
end
