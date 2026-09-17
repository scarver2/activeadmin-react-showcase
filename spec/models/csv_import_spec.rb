# spec/models/csv_import_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvImport do
  subject(:csv_import) { build(:csv_import) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to have_many(:csv_import_rows).dependent(:destroy) }
  it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  it { is_expected.to validate_uniqueness_of(:token) }

  it "round trips mappings and errors and exposes bounded metadata" do
    csv_import.mappings = { email: "email" }
    csv_import.row_errors = [ "bad row" ]
    expect(csv_import.mappings).to eq("email" => "email")
    expect(csv_import.row_errors).to eq([ "bad row" ])
    expect(csv_import.broadcast_key).to eq("csv_import:#{csv_import.token}")
    expect(described_class.ransackable_attributes).to include("status")
    expect(described_class.ransackable_associations).to eq([ "admin_user" ])
  end
end
