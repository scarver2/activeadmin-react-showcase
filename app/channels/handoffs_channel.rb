# app/channels/handoffs_channel.rb
# frozen_string_literal: true

class HandoffsChannel < ApplicationCable::Channel
  def subscribed
    item = current_admin_user.handoff_items.find_by(public_id: params[:item_id])
    return reject unless item

    stream_from item.broadcast_key
  end
end
