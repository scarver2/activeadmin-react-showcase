# spec/jobs/process_csv_import_job_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessCsvImportJob do
  let!(:bluebonnet) { create(:account, name: "Bluebonnet Logistics") }
  let!(:cedar) { create(:account, name: "Cedar Ridge Health") }
  let(:csv_import) do
    create(:csv_import, status: "queued", row_count: 2).tap do |item|
      item.update!(mappings: { first_name: "first_name", last_name: "last_name", email: "email", account: "account" })
    end
  end

  it "partially imports valid rows, persists progress, and is replay safe" do
    expect do
      expect { described_class.perform_now(csv_import.id) }.to have_broadcasted_to(csv_import.broadcast_key).at_least(:once)
    end.to change(Contact, :count).by(2)
    expect(csv_import.reload).to have_attributes(status: "completed", processed_rows: 2, imported_rows: 2, failed_rows: 0)
    expect { described_class.perform_now(csv_import.id) }.not_to change(Contact, :count)
  end

  it "persists row failures while continuing valid work" do
    bluebonnet.destroy!
    described_class.perform_now(csv_import.id)
    expect(csv_import.reload).to have_attributes(status: "completed", processed_rows: 2, imported_rows: 1, failed_rows: 1)
    expect(csv_import.row_errors.join).to include("Account must exist")
  end

  it "persists unexpected terminal failures and reraises" do
    allow(CsvImports::Reader).to receive(:new).and_raise("storage unavailable")
    expect { described_class.perform_now(csv_import.id) }.to raise_error("storage unavailable")
    expect(csv_import.reload).to have_attributes(status: "failed", row_errors: [ "storage unavailable" ])
  end
end
