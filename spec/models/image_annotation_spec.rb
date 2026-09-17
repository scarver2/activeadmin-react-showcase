# spec/models/image_annotation_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnnotation do
  let(:asset) { ShowcaseAssets::Seed.call.find { |item| item.file.image? } }

  it "accepts bounded normalized metadata for an image" do
    annotation = described_class.new(
      admin_user: create(:admin_user), showcase_asset: asset, focal_x: 0.2, focal_y: 0.8,
      region_x: 0.1, region_y: 0.1, region_width: 0.4, region_height: 0.4,
      edit_specification: described_class::DEFAULT_EDIT_SPECIFICATION.merge("crop_x" => 0.1, "crop_width" => 0.8, "rotation" => 90)
    )
    expect(annotation).to be_valid
    expect(annotation.canonical_edit_specification).to include("crop_x" => 0.1, "rotation" => 90)
  end

  it "rejects invalid coordinates, labels, regions, and non-images" do
    annotation = described_class.new(admin_user: create(:admin_user), showcase_asset: asset, focal_x: 2, focal_y: 0.5, label: "Script", region_x: 0.8, region_y: 0.8, region_width: 0.5, region_height: 0.5)
    expect(annotation).not_to be_valid
    text = ShowcaseAssets::Seed.call.find { |item| !item.file.image? }
    expect(described_class.new(admin_user: create(:admin_user), showcase_asset: text)).not_to be_valid
  end

  it "rejects unsupported, malformed, and out-of-bounds edit recipes" do
    admin = create(:admin_user)
    invalid_recipes = [
      { "unknown_filter" => true },
      { "brightness" => 4 },
      { "crop_x" => 0.8, "crop_width" => 0.4 },
      { "crop_width" => 0 },
      { "rotation" => 45 },
      { "flip_x" => "sometimes" }
    ]

    invalid_recipes.each do |recipe|
      annotation = described_class.new(admin_user: admin, showcase_asset: asset, edit_specification: described_class::DEFAULT_EDIT_SPECIFICATION.merge(recipe))
      expect(annotation).not_to be_valid
    end
  end
end
