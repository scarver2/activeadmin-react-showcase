# app/models/showcase_asset.rb
# frozen_string_literal: true

class ShowcaseAsset < ApplicationRecord
  has_many :image_annotations, dependent: :destroy
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg application/pdf text/plain].freeze
  MAXIMUM_BYTES = 5.megabytes

  has_one_attached :file

  validates :title, length: { in: 1..80 }
  validate :acceptable_file

  private

  def acceptable_file
    return errors.add(:file, "must be attached") unless file.attached?

    errors.add(:file, "type is not allowed") unless ALLOWED_CONTENT_TYPES.include?(file.blob.content_type)
    errors.add(:file, "must be 5 MB or smaller") if file.blob.byte_size > MAXIMUM_BYTES
  end
end
