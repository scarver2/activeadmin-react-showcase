# spec/factories/csv_imports.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :csv_import do
    association :admin_user
    token { SecureRandom.uuid }

    after(:build) do |csv_import|
      next if csv_import.source.attached?

      csv_import.source.attach(
        io: Rails.root.join("spec/fixtures/files/contacts.csv").open,
        filename: "contacts.csv",
        content_type: "text/csv"
      )
    end
  end
end
