# spec/services/geospatial_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Geospatial::LocationQuery do
  it "returns only locations inside a valid bounded viewport with Rails URLs" do
    inside = create(:showcase_location)
    create(:showcase_location, latitude: 45, longitude: -120)
    payload = described_class.new(bounds: "-100,28,-95,32").as_json
    expect(payload[:locations]).to contain_exactly(include(id: inside.id.to_s, url: Rails.application.routes.url_helpers.admin_showcase_location_path(inside)))
  end

  it "rejects malformed, unordered, invalid, and excessive bounds" do
    [ "bad", "-97,30,-98,31", "-181,30,-97,31", "-110,20,-90,40" ].each do |bounds|
      expect { described_class.new(bounds:) }.to raise_error(ArgumentError)
    end
  end

  it "seeds deterministic locations idempotently" do
    create(:showcase_location, name: "Obsolete Central Texas fixture")
    expect { Geospatial::Seed.call }.to change(ShowcaseLocation, :count).from(1).to(7)
    expect { Geospatial::Seed.call }.not_to change(ShowcaseLocation, :count)
    expect(ShowcaseLocation.order(:name).pluck(:name)).to include("Texas Embroidery Ranch", "Sherley Heritage Park")
    expect(ShowcaseLocation).not_to exist(name: "Obsolete Central Texas fixture")
  end
end
