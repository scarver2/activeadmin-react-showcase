# app/services/showcase_assets/serializer.rb
# frozen_string_literal: true

module ShowcaseAssets
  class Serializer
    def initialize(asset)
      @asset = asset
    end

    def as_json(*)
      {
        id: asset.id,
        title: asset.title,
        filename: asset.file.filename.to_s,
        contentType: asset.file.content_type,
        byteSize: asset.file.byte_size,
        previewKind: preview_kind,
        url: Rails.application.routes.url_helpers.rails_blob_path(asset.file, only_path: true, disposition: "inline"),
        deleteUrl: Rails.application.routes.url_helpers.admin_showcase_asset_path(asset)
      }
    end

    private

    attr_reader :asset

    def preview_kind
      asset.file.image? ? "image" : "download"
    end
  end
end
