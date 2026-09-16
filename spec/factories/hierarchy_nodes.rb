# spec/factories/hierarchy_nodes.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :hierarchy_node do
    association :admin_user
    sequence(:title) { |index| "Hierarchy node #{index}" }
    position { 0 }
  end
end
