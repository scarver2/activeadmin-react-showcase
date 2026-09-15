# spec/models/material_sphere_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaterialSphere do
  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_inclusion_of(:finish).in_array(MaterialStudio::Catalog.ids) }
  it { is_expected.to validate_presence_of(:name) }
  it("allowlists searches") { expect(described_class.ransackable_attributes).to include("finish", "lock_version") }
end
