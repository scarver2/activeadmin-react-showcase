# app/services/image_editor/save.rb
# frozen_string_literal: true

module ImageEditor
  class Save
    ATTRIBUTES = %i[focal_x focal_y label region_height region_width region_x region_y].freeze

    def self.call(admin_user:, asset:, attributes:)
      raise ActiveRecord::RecordInvalid, asset unless asset.file.image?
      annotation = admin_user.image_annotations.find_or_initialize_by(showcase_asset: asset)
      annotation.update!(attributes.slice(*ATTRIBUTES).to_h)
      annotation
    end
  end
end
