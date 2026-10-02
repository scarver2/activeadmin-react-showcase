# app/services/handoffs/transition.rb
# frozen_string_literal: true

module Handoffs
  # Lock + expected version serialize competing commands; receipts make retries safe.
  # The demo's advance command simulates a bounded provider step, not an AI API.
  class Transition
    class Conflict < StandardError; end

    def self.call(item:, admin_user:, action:, command_id:, version:)
      raise ActiveRecord::RecordNotFound unless item.admin_user_id == admin_user.id
      raise ArgumentError, "Invalid command identity" unless command_id.to_s.match?(HandoffEvent::COMMAND_ID_PATTERN)

      item.with_lock do
        receipt = item.events.find_by(command_id:)
        if receipt
          raise Conflict, "Command identity already used" unless receipt.action == action

          next item
        end
        raise Conflict, "Work changed; refresh before acting" unless Integer(version, exception: false) == item.lock_version

        state, progress, actor, evidence = result(item, action)
        item.update!(state:, progress:)
        item.events.create!(sequence: item.events.count + 1, command_id:, action:, actor:, evidence:)
      end
      # Cable is an optional invalidation hint. The committed snapshot is the truth.
      begin
        ActionCable.server.broadcast(item.broadcast_key, { version: item.lock_version })
      rescue StandardError => error
        Rails.logger.warn("Handoff live hint unavailable: #{error.class}")
      end
      item
    rescue ActiveRecord::StaleObjectError
      raise Conflict, "Work changed; refresh before acting"
    rescue ActiveRecord::StatementInvalid => error
      raise unless error.cause.class.name.in?(%w[SQLite3::BusyException SQLite3::LockedException])

      raise Conflict, "Work is busy; refresh before retrying"
    end

    def self.result(item, action)
      case [ item.state, action ]
      when [ "human", "assign" ]
        [ "agent", 0, "human", "Human assigned a synthetic checklist to deterministic demo agent v1." ]
      when [ "agent", "advance" ]
        progress = [ item.progress + 25, 75 ].min
        state = progress == 75 ? "approval" : "agent"
        [ state, progress, "deterministic_agent", "Synthetic checklist step #{progress / 25}/3 checked. No external calls or real records changed." ]
      when [ "approval", "approve" ]
        [ "completed", 100, "human", "Human approved the synthetic evidence and accepted completion." ]
      when [ "agent", "hand_back" ], [ "approval", "hand_back" ]
        [ "human", item.progress, "human", "Human intervened and reclaimed the work. Prior evidence retained." ]
      when [ "human", "cancel" ], [ "agent", "cancel" ], [ "approval", "cancel" ]
        [ "cancelled", item.progress, "human", "Human cancelled the work. Further agent steps are rejected." ]
      else
        raise Conflict, "That action is unavailable in the current state"
      end
    end
    private_class_method :result
  end
end
