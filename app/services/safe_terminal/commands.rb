# app/services/safe_terminal/commands.rb
# frozen_string_literal: true

module SafeTerminal
  class Commands
    Unsupported = Class.new(ArgumentError)

    DEFINITIONS = {
      "showcase:backup:verify" => {
        label: "Verify backup fixture",
        steps: [
          [ "stdout", "Opening the synthetic SQLite snapshot." ],
          [ "stdout", "Verifying fixture checksum: sha256/demo-safe." ],
          [ "stdout", "Restore drill metadata is internally consistent." ]
        ]
      },
      "showcase:deploy:plan" => {
        label: "Preview deployment plan",
        steps: [
          [ "stdout", "Loading the fixed single-host deployment fixture." ],
          [ "stdout", "Plan: migrate, restart, verify health, retain previous image." ],
          [ "stdout", "No infrastructure changes are required." ]
        ]
      },
      "showcase:status" => {
        label: "Inspect showcase status",
        steps: [
          [ "stdout", "Rails application: ready." ],
          [ "stdout", "SQLite and Solid services: configured." ],
          [ "stdout", "Synthetic health checks: passing." ]
        ]
      }
    }.freeze

    def self.fetch(key)
      DEFINITIONS.fetch(key.to_s) { raise Unsupported, "Command is not allowlisted" }
    end

    def self.keys
      DEFINITIONS.keys
    end

    def self.options
      DEFINITIONS.map { |key, definition| { key:, label: definition.fetch(:label) } }
    end
  end
end
