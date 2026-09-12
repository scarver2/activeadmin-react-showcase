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
end
