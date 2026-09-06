# app/channels/operations_channel.rb
# frozen_string_literal: true

class OperationsChannel < ApplicationCable::Channel
  def resume(data)
    after_sequence = Integer(data["after_sequence"], exception: false)
    return if after_sequence.nil? || after_sequence.negative?

    operation.events.where(sequence: (after_sequence + 1)..).find_each { |event| transmit(event.envelope) }
  end

  private

  attr_reader :operation

  def subscribed
    @operation = current_admin_user.operations.find_by(public_id: params[:operation_id])
    return reject unless operation

    stream_from(operation.broadcast_key)
    transmit(operation.latest_envelope)
  end
end
