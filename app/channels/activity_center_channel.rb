# app/channels/activity_center_channel.rb
# frozen_string_literal: true

class ActivityCenterChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_admin_user

    stream_from(ActivityCenter::Create.channel_for(current_admin_user), coder: ActiveSupport::JSON)
    replay_after(params[:after_sequence])
  end

  private

  def replay_after(raw_sequence)
    sequence = Integer(raw_sequence || 0, exception: false)
    return reject if sequence.nil? || sequence.negative?

    current_admin_user.activity_notifications.where(sequence: (sequence + 1)..).order(:sequence).limit(100).each do |item|
      transmit({ type: "notification", notification: ActivityCenter::Serializer.new(item).as_json })
    end
  end
end
