# spec/factories/onboarding_drafts.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :onboarding_draft do
    admin_user
    company_name { "Bluebonnet Works" }
    contact_email { "operator@example.test" }
  end
end
