# spec/factories/operations.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :operation do
    admin_user
    kind { "successful_demo" }
    state { "queued" }
  end
end
