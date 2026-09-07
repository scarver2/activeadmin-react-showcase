# spec/models/showcase_asset_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowcaseAsset do
  it "accepts an allowlisted bounded attachment" do
    expect(build(:showcase_asset)).to be_valid
  end

  it "requires a file and bounded title" do
    asset = described_class.new(title: "")

    expect(asset).not_to be_valid
    expect(asset.errors[:file]).to include("must be attached")
  end

  it "rejects unsupported and oversized uploads" do
    unsupported = described_class.new(title: "Executable")
    unsupported.file.attach(io: StringIO.new("binary"), filename: "unsafe.bin", content_type: "application/octet-stream")
    oversized = described_class.new(title: "Large")
    oversized.file.attach(io: StringIO.new("x" * (described_class::MAXIMUM_BYTES + 1)), filename: "large.txt", content_type: "text/plain")

    expect(unsupported).not_to be_valid
    expect(unsupported.errors[:file]).to include("type is not allowed")
    expect(oversized).not_to be_valid
    expect(oversized.errors[:file]).to include("must be 5 MB or smaller")
  end
end
