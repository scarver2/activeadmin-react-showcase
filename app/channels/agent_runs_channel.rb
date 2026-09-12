# app/channels/agent_runs_channel.rb
# frozen_string_literal: true

class AgentRunsChannel < ApplicationCable::Channel
  def subscribed
    @run = current_admin_user.agent_runs.find_by(public_id: params[:run_id])
    return reject unless @run

    @delivery_mutex = Mutex.new
    @pending_events = []
    @live = false
    stream_from(@run.broadcast_key, coder: ActiveSupport::JSON) { |event| deliver_or_buffer(event) }
  end

  def resume(data)
    after = Integer(data["after_sequence"], exception: false)
    return unless after&.>= 0

    @delivery_mutex.synchronize do
      @live = false
      replay_from([ after, @last_delivered_sequence.to_i ].max)
      @pending_events.sort_by { |event| sequence(event) }.each { |event| deliver(event) }
      @pending_events.clear
      @live = true
    end
  end

  private

  def deliver(event)
    return unless sequence(event) > @last_delivered_sequence.to_i

    transmit(event)
    @last_delivered_sequence = sequence(event)
  end

  def deliver_or_buffer(event)
    @delivery_mutex.synchronize { @live ? deliver(event) : @pending_events << event }
  end

  def replay_from(after)
    @run.events.where(sequence: (after + 1)..).order(:sequence).each { |event| deliver(event.envelope) }
  end

  def sequence(event)
    event.fetch("sequence") { event.fetch(:sequence) }
  end
end
