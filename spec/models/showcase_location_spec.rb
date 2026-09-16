# spec/models/showcase_location_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowcaseLocation do
  subject(:location) { build(:showcase_location) }
  it { is_expected.to validate_presence_of(:category) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:summary) }
  it { is_expected.to validate_numericality_of(:latitude).is_in(-90..90) }
  it { is_expected.to validate_numericality_of(:longitude).is_in(-180..180) }

  it "allowlists searchable attributes" do
    expect(described_class.ransackable_attributes).to include("name", "latitude", "longitude")
  end
end
