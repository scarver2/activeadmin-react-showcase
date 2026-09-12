# spec/models/content_document_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentDocument do
  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to have_many(:content_blocks).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }
  it("allowlists searches") { expect(described_class.ransackable_attributes).to include("title") }
end

RSpec.describe ContentBlock do
  it { is_expected.to belong_to(:content_document) }
  it { is_expected.to validate_inclusion_of(:block_type).in_array(described_class::TYPES) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:body).is_at_most(500) }
  it { is_expected.to validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
  it("allowlists searches") { expect(described_class.ransackable_attributes).to include("block_type", "position") }
end
