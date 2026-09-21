# spec/channels/csv_import_channel_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvImportChannel, type: :channel do
  let(:admin_user) { create(:admin_user) }
  let(:csv_import) { create(:csv_import, admin_user:) }

  it "streams and transmits durable progress to the owner" do
    stub_connection current_admin_user: admin_user
    subscribe(token: csv_import.token)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(csv_import.broadcast_key)
    expect(transmissions.dig(0, "import", "token")).to eq(csv_import.token)
  end

  it "rejects missing, foreign, and unauthenticated imports" do
    stub_connection current_admin_user: create(:admin_user)
    subscribe(token: csv_import.token)
    expect(subscription).to be_rejected
  end

  it "reconciles work completed between the initial snapshot and stream confirmation" do
    stub_connection current_admin_user: admin_user
    subscribe(token: csv_import.token)
    csv_import.update!(status: "completed", processed_rows: 2, imported_rows: 1, failed_rows: 1)

    perform :refresh

    expect(transmissions.last.fetch("import")).to include(
      "status" => "completed", "processedRows" => 2, "importedRows" => 1, "failedRows" => 1
    )
  end

  it "does not refresh an import after ownership is lost" do
    stub_connection current_admin_user: admin_user
    subscribe(token: csv_import.token)
    csv_import.update!(admin_user: create(:admin_user))

    expect { perform :refresh }.not_to change(transmissions, :size)
    expect(subscription).to be_rejected
  end
end
