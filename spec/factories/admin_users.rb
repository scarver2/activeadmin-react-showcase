# spec/factories/admin_users.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |number| "admin-#{number}@example.test" }
    password { "showcase-password" }
    password_confirmation { password }
  end
end
