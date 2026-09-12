# spec/factories/terminal_outputs.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :terminal_output do
    association :terminal_execution
    occurred_at { Time.current }
    add_attribute(:sequence) { 1 }
    stream { "stdout" }
    text { "Synthetic output" }
  end
end
