# app/channels/safe_terminal_channel.rb
# frozen_string_literal: true

class SafeTerminalChannel < ApplicationCable::Channel
  def resume(data)
    after_sequence = Integer(data["after_sequence"], exception: false)
    return if after_sequence.nil? || after_sequence.negative?

    delivery_mutex.synchronize do
      @live = false
      replay_from([ after_sequence, last_delivered_sequence.to_i ].max)
      flush_pending
      @live = true
    end
  end

  private

  attr_reader :delivery_mutex, :execution, :last_delivered_sequence, :pending

  def subscribed
    @execution = current_admin_user&.terminal_executions&.find_by(public_id: params[:operation_id])
    return reject unless execution

    @delivery_mutex = Mutex.new
    @pending = []
    @live = false
    stream_from(execution.broadcast_key, coder: ActiveSupport::JSON) { |envelope| deliver_or_hold(envelope) }
  end

  def deliver(envelope)
    transmit(envelope)
    @last_delivered_sequence = sequence(envelope)
  end

  def deliver_or_hold(envelope)
    delivery_mutex.synchronize do
      return pending << envelope unless @live

      deliver(envelope) if sequence(envelope) > last_delivered_sequence.to_i
    end
  end

  def flush_pending
    pending.uniq { |envelope| sequence(envelope) }.sort_by { |envelope| sequence(envelope) }.each do |envelope|
      deliver(envelope) if sequence(envelope) > last_delivered_sequence.to_i
    end
    pending.clear
  end

  def replay_from(after_sequence)
    execution.outputs.where(sequence: (after_sequence + 1)..).order(:sequence).each do |output|
      deliver(SafeTerminal::Serializer.envelope(execution.reload, output))
    end
  end

  def sequence(envelope)
    output = envelope.fetch("output") { envelope.fetch(:output) }
    output.fetch("sequence") { output.fetch(:sequence) }
  end
end
