# spec/models/image_annotation_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnnotation do
  let(:asset) { ShowcaseAssets::Seed.call.find { |item| item.file.image? } }

  it "accepts bounded normalized metadata for an image" do
    annotation = described_class.new(admin_user: create(:admin_user), showcase_asset: asset, focal_x: 0.2, focal_y: 0.8, region_x: 0.1, region_y: 0.1, region_width: 0.4, region_height: 0.4)
    expect(annotation).to be_valid
  end

  it "rejects invalid coordinates, labels, regions, and non-images" do
    annotation = described_class.new(admin_user: create(:admin_user), showcase_asset: asset, focal_x: 2, focal_y: 0.5, label: "Script", region_x: 0.8, region_y: 0.8, region_width: 0.5, region_height: 0.5)
    expect(annotation).not_to be_valid
    text = ShowcaseAssets::Seed.call.find { |item| !item.file.image? }
    expect(described_class.new(admin_user: create(:admin_user), showcase_asset: text)).not_to be_valid
  end
end
