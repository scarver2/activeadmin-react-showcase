# spec/factories/workflow_items.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_item do
    sequence(:title) { |number| "Workflow item #{number}" }
    context { "Synthetic workflow context" }
    state { "backlog" }
    sequence(:position) { |number| number }
  end
end
