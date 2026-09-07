# app/channels/operator_chat_channel.rb
# frozen_string_literal: true

class OperatorChatChannel < ApplicationCable::Channel
  def subscribed
    @room = ChatRoom.find_by(public_id: params[:room_id])
    return reject unless current_admin_user && @room

    stream_from(@room.broadcast_key, coder: ActiveSupport::JSON)
    replay_after(params[:after_sequence])
  end

  private

  def replay_after(raw_sequence)
    sequence = Integer(raw_sequence || 0, exception: false)
    return reject if sequence.nil? || sequence.negative?

    @room.messages.includes(:author).where(sequence: (sequence + 1)..).order(:sequence).limit(100).each do |message|
      transmit({ type: "message", message: OperatorChat::Serializer.new(message).as_json })
    end
  end
end
