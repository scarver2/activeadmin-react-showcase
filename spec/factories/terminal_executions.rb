# spec/factories/terminal_executions.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :terminal_execution do
    association :admin_user
    command_key { "showcase:status" }
    display_command { command_key }
    idempotency_key { SecureRandom.uuid }
  end
end
