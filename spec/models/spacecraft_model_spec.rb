# spec/models/spacecraft_model_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpacecraftModel do
  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_inclusion_of(:finish).in_array(described_class::FINISHES) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_inclusion_of(:selected_component_id).in_array(Spacecraft::Catalog.ids) }
  it("allowlists searches") { expect(described_class.ransackable_attributes).to include("finish", "selected_component_id") }
end
