# app/services/safe_terminal/broadcast.rb
# frozen_string_literal: true

module SafeTerminal
  class Broadcast
    def self.call(execution, output)
      ActionCable.server.broadcast(execution.broadcast_key, Serializer.envelope(execution, output))
    rescue StandardError => e
      Rails.logger.error("Terminal output #{output.id} Cable broadcast failed: #{e.class}: #{e.message}")
    end
  end
end
