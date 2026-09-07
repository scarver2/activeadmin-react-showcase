# spec/requests/admin/showcase_assets_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin showcase assets" do
  let(:upload) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.txt"), "text/plain") }

  before { sign_in create(:admin_user) }

  it "uploads an allowlisted file through an authenticated command" do
    post admin_showcase_assets_path, params: { title: "Browser fixture", file: upload }, headers: { "ACCEPT" => "application/json" }

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("title" => "Browser fixture", "previewKind" => "download")
    expect(ShowcaseAsset.last.file).to be_attached
  end

  it "returns validation errors and supports the HTML fallback" do
    post admin_showcase_assets_path, params: { title: "x" * 81, file: upload }, headers: { "ACCEPT" => "application/json" }
    expect(response).to have_http_status(:unprocessable_content)

    post admin_showcase_assets_path, params: { title: "Fallback", file: upload }
    expect(response).to redirect_to(admin_file_image_manager_path)
  end

  it "deletes assets through JSON and HTML fallbacks" do
    asset = create(:showcase_asset)
    delete admin_showcase_asset_path(asset), as: :json
    expect(response).to have_http_status(:no_content)
    expect(ShowcaseAsset.where(id: asset.id)).to be_empty

    fallback_asset = create(:showcase_asset)
    delete admin_showcase_asset_path(fallback_asset)
    expect(response).to redirect_to(admin_file_image_manager_path)
    expect(ShowcaseAsset.where(id: fallback_asset.id)).to be_empty
  end

  it "renders only persisted records without seeding during the request" do
    create(:showcase_asset, title: "Persisted fixture")

    expect { get admin_file_image_manager_path }.not_to change(ShowcaseAsset, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Persisted fixture", "Upload asset", "Delete")
    expect(ShowcaseAsset.pluck(:title)).to eq([ "Persisted fixture" ])
  end

  it "requires an authenticated administrator" do
    sign_out :admin_user
    post admin_showcase_assets_path, params: { title: "Denied", file: upload }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
