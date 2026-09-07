# spec/services/showcase_assets_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Showcase assets" do
  it "seeds one image and one downloadable file idempotently" do
    assets = ShowcaseAssets::Seed.call
    ShowcaseAssets::Seed.call

    expect(assets.pluck(:title)).to eq([ "Bluebonnet product sample", "Synthetic fulfillment notes" ])
    expect(assets.map { |asset| ShowcaseAssets::Serializer.new(asset).as_json }.pluck(:previewKind)).to eq(%w[image download])
  end

  it "purges uploaded data and restores the safe fixture" do
    create(:showcase_asset, title: "Temporary")

    assets = ShowcaseAssets::Seed.reset

    expect(assets.pluck(:title)).to eq([ "Bluebonnet product sample", "Synthetic fulfillment notes" ])
    expect(ShowcaseAsset.where(title: "Temporary")).to be_empty
  end
end
