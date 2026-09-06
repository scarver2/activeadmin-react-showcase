# app/channels/operations_channel.rb
# frozen_string_literal: true

class OperationsChannel < ApplicationCable::Channel
  def resume(data)
    after_sequence = Integer(data["after_sequence"], exception: false)
    return if after_sequence.nil? || after_sequence.negative?

    delivery_mutex.synchronize do
      @live = false
      replay_from([ after_sequence, last_delivered_sequence.to_i ].max)
      flush_pending_events
      @live = true
    end
  end

  def unsubscribed
    cable_tracker.disconnected(session_id) if session_id
  end

  private

  attr_reader :delivery_mutex, :last_delivered_sequence, :operation, :pending_events, :session_id

  def subscribed
    @operation = current_admin_user.operations.find_by(public_id: params[:operation_id])
    return reject unless operation

    @session_id = SecureRandom.uuid
    @delivery_mutex = Mutex.new
    @pending_events = []
    @live = false
    cable_tracker.connected(session_id)
    stream_from(operation.broadcast_key, coder: ActiveSupport::JSON) { |event| deliver_or_buffer(event) }
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
    delivery_mutex.synchronize do
      return pending_events << event unless @live

      sequence = event.fetch("sequence") { event.fetch(:sequence) }
      deliver(event, kind: :live) if sequence > last_delivered_sequence.to_i
    end
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
