# spec/factories/contacts.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    account
    sequence(:email) { |number| "contact-#{number}@example.test" }
    first_name { "Morgan" }
    job_title { "Operations Director" }
    last_name { "Reyes" }
    relationship_role { "Operations lead" }
  end
end
