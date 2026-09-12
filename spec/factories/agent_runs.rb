# spec/factories/agent_runs.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :agent_run do
    admin_user
    prompt { "Which synthetic accounts need attention?" }
  end
end
