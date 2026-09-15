# app/services/showcase_assets/seed.rb
# frozen_string_literal: true

module ShowcaseAssets
  class Seed
    IMAGE_PATH = Rails.root.join("db/seeds/assets/bluebonnet-showcase.png")

    def self.call
      seed_asset(title: "Bluebonnet product sample", filename: "bluebonnet.png", content_type: "image/png", contents: IMAGE_PATH.binread)
      seed_asset(title: "Synthetic fulfillment notes", filename: "fulfillment-notes.txt", content_type: "text/plain", contents: "Synthetic showcase notes.\n")
      ShowcaseAsset.order(:id)
    end

    def self.reset
      ShowcaseAsset.find_each do |asset|
        asset.file.purge
        asset.destroy!
      end
      call
    end

    def self.seed_asset(title:, filename:, content_type:, contents:)
      asset = ShowcaseAsset.find_or_initialize_by(title:)
      return asset if asset.persisted? && asset.file.attached?

      asset.file.attach(io: StringIO.new(contents), filename:, content_type:)
      asset.save!
      asset
    end
    private_class_method :seed_asset
  end
end
