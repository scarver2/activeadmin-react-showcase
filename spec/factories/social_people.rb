# spec/factories/social_people.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :social_person do
    admin_user
    headline { "Engineer" }
    sequence(:name) { |number| "Person #{number}" }
  end
  factory :social_connection do
    association :person_a, factory: :social_person
    association :person_b, factory: :social_person
  end
end
