# app/services/showcase_assets/seed.rb
# frozen_string_literal: true

require "base64"

module ShowcaseAssets
  class Seed
    PIXEL = Base64.strict_decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")

    def self.call
      seed_asset(title: "Bluebonnet product sample", filename: "bluebonnet.png", content_type: "image/png", contents: PIXEL)
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
