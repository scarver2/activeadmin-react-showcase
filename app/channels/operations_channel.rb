# app/channels/operations_channel.rb
# frozen_string_literal: true

class OperationsChannel < ApplicationCable::Channel
  def resume(data)
    after_sequence = Integer(data["after_sequence"], exception: false)
    return if after_sequence.nil? || after_sequence.negative?

    @replaying = true
    replay_from(after_sequence)
    @replaying = false
    flush_pending_events
  end

  def unsubscribed
    cable_tracker.disconnected(session_id) if session_id
  end

  private

  attr_reader :last_delivered_sequence, :operation, :pending_events, :session_id

  def subscribed
    @operation = current_admin_user.operations.find_by(public_id: params[:operation_id])
    return reject unless operation

    @session_id = SecureRandom.uuid
    @pending_events = []
    @replaying = true
    cable_tracker.connected(session_id)
    stream_from(operation.broadcast_key, coder: ActiveSupport::JSON) { |event| deliver_or_buffer(event) }
    after_sequence = Integer(params[:after_sequence], exception: false)
    replay_from(after_sequence && after_sequence >= 0 ? after_sequence : 0)
    @replaying = false
    flush_pending_events
  end

  def cable_tracker
    Rails.application.config.x.showcase_cable_tracker
  end

  def deliver(event, kind:)
    transmit(event)
    cable_tracker.delivered(kind)
    @last_delivered_sequence = event.fetch("sequence") { event.fetch(:sequence) }
  end

  def deliver_or_buffer(event)
    return pending_events << event if @replaying

    deliver(event, kind: :live)
  end

  def flush_pending_events
    pending_events
      .uniq { |event| event.fetch("sequence") { event.fetch(:sequence) } }
      .sort_by { |event| event.fetch("sequence") { event.fetch(:sequence) } }
      .each do |event|
        sequence = event.fetch("sequence") { event.fetch(:sequence) }
        deliver(event, kind: :live) if sequence > last_delivered_sequence.to_i
      end
    pending_events.clear
  end

  def replay_from(after_sequence)
    operation.events.where(sequence: (after_sequence + 1)..).order(:sequence).each do |event|
      deliver(event.envelope, kind: :replay)
    end
  end
end
