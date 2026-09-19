# spec/requests/admin/image_annotations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin image annotations" do
  let(:admin) { create(:admin_user) }
  let(:image) { ShowcaseAssets::Seed.call.find { |asset| asset.file.image? } }

  before { sign_in admin }

  it "persists and reloads normalized metadata" do
    original_checksum = image.file.blob.checksum
    patch admin_image_annotation_path(image), params: {
      focal_x: 0.25, focal_y: 0.75, label: "Logo",
      edit_specification: { brightness: "1.25", contrast: 1.1, crop_height: 0.7, crop_width: 0.6, crop_x: 0.1, crop_y: 0.2, flip_x: "1", flip_y: false, grayscale: true, rotation: "90", saturation: 0, sepia: false }
    }, as: :json
    expect(response).to have_http_status(:ok)
    annotation = admin.image_annotations.find_by!(showcase_asset: image)
    expect(annotation.focal_x).to eq(0.25)
    expect(annotation.edit_specification).to include("brightness" => 1.25, "flip_x" => true, "grayscale" => true, "rotation" => 90.0)
    expect(response.parsed_body.fetch("edit_specification")).to include("crop_width" => 0.6, "saturation" => 0.0)
    expect(image.file.blob.reload.checksum).to eq(original_checksum)
  end

  it "reports invalid and mislabeled asset metadata" do
    patch admin_image_annotation_path(image), params: { focal_x: 4, focal_y: 0.5, label: "Subject" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    text = ShowcaseAssets::Seed.call.find { |asset| !asset.file.image? }
    patch admin_image_annotation_path(text), params: { focal_x: 0.5, focal_y: 0.5, label: "Subject" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects an invalid transformation recipe" do
    patch admin_image_annotation_path(image), params: { edit_specification: ImageAnnotation::DEFAULT_EDIT_SPECIFICATION.merge("crop_x" => 0.8, "crop_width" => 0.5) }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("error")).to include("crop must stay inside")
  end
end
