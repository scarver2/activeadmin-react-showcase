# spec/factories/showcase_assets.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :showcase_asset do
    sequence(:title) { |number| "Synthetic asset #{number}" }

    after(:build) do |asset|
      next if asset.file.attached?

      asset.file.attach(io: StringIO.new("Synthetic content"), filename: "sample.txt", content_type: "text/plain")
    end
  end
end
