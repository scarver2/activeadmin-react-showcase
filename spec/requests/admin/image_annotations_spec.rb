# spec/requests/admin/image_annotations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin image annotations" do
  let(:admin) { create(:admin_user) }
  let(:image) { ShowcaseAssets::Seed.call.find { |asset| asset.file.image? } }

  before { sign_in admin }

  it "persists and reloads normalized metadata" do
    patch admin_image_annotation_path(image), params: { focal_x: 0.25, focal_y: 0.75, label: "Logo" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(admin.image_annotations.find_by!(showcase_asset: image).focal_x).to eq(0.25)
  end

  it "reports invalid and mislabeled asset metadata" do
    patch admin_image_annotation_path(image), params: { focal_x: 4, focal_y: 0.5, label: "Subject" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    text = ShowcaseAssets::Seed.call.find { |asset| !asset.file.image? }
    patch admin_image_annotation_path(text), params: { focal_x: 0.5, focal_y: 0.5, label: "Subject" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end
end
