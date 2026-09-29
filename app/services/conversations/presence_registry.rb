# app/services/conversations/presence_registry.rb
# frozen_string_literal: true

require "monitor"

module Conversations
  class PresenceRegistry
    ONLINE_TTL = 45.seconds
    TYPING_TTL = 5.seconds

    Session = Data.define(:membership_id, :display_name, :seen_at, :typing_until)
    Transition = Data.define(:changed, :snapshot)

    def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @clock = clock
      @monitor = Monitor.new
      @sessions = Hash.new { |conversations, conversation_id| conversations[conversation_id] = {} }
    end

    def join(conversation_id:, session_id:, membership:)
      change(conversation_id:) do |sessions, now|
        sessions[session_id] = Session.new(
          membership_id: membership.id,
          display_name: membership.display_name,
          seen_at: now,
          typing_until: nil
        )
      end
    end

    def heartbeat(conversation_id:, session_id:, membership:)
      change(conversation_id:) do |sessions, now|
        session = sessions[session_id]
        sessions[session_id] = session&.with(seen_at: now) || Session.new(
          membership_id: membership.id,
          display_name: membership.display_name,
          seen_at: now,
          typing_until: nil
        )
      end
    end

    def typing(conversation_id:, session_id:, active:)
      change(conversation_id:) do |sessions, now|
        session = sessions[session_id]
        next unless session

        sessions[session_id] = session.with(
          seen_at: now,
          typing_until: active ? now + TYPING_TTL.to_f : nil
        )
      end
    end

    def leave(conversation_id:, session_id:)
      change(conversation_id:) { |sessions, _now| sessions.delete(session_id) }
    end

    def expire(conversation_id:)
      @monitor.synchronize do
        sessions = @sessions.fetch(conversation_id, {})
        now = @clock.call
        before = visible_snapshot(sessions, now:, include_expired: true)
        prune!(sessions, now:)
        cleanup!(conversation_id, sessions)
        after = visible_snapshot(sessions, now:)
        Transition.new(changed: before != after, snapshot: after)
      end
    end

    def snapshot(conversation_id:)
      @monitor.synchronize do
        sessions = @sessions.fetch(conversation_id, {})
        now = @clock.call
        prune!(sessions, now:)
        cleanup!(conversation_id, sessions)
        visible_snapshot(sessions, now:)
      end
    end

    private

    def change(conversation_id:)
      @monitor.synchronize do
        sessions = @sessions[conversation_id]
        now = @clock.call
        before = visible_snapshot(sessions, now:)
        prune!(sessions, now:)
        yield sessions, now
        after = visible_snapshot(sessions, now:)
        cleanup!(conversation_id, sessions)
        Transition.new(changed: before != after, snapshot: after)
      end
    end

    def cleanup!(conversation_id, sessions)
      @sessions.delete(conversation_id) if sessions.empty?
    end

    def prune!(sessions, now:)
      sessions.delete_if { |_session_id, session| session.seen_at + ONLINE_TTL.to_f <= now }
      sessions.transform_values! do |session|
        next session unless session.typing_until && session.typing_until <= now

        session.with(typing_until: nil)
      end
    end

    def visible_snapshot(sessions, now:, include_expired: false)
      visible = sessions.values.select do |session|
        include_expired || session.seen_at + ONLINE_TTL.to_f > now
      end
      grouped = visible.group_by(&:membership_id)
      {
        online: grouped.values.map { |member_sessions| member_sessions.first.display_name }.sort,
        typing: grouped.values.filter_map do |member_sessions|
          next unless member_sessions.any? do |session|
            session.typing_until && (include_expired || session.typing_until > now)
          end

          member_sessions.first.display_name
        end.sort
      }
    end
  end
end
