# spec/services/csv_imports_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvImports do
  let(:admin_user) { create(:admin_user) }
  let(:source) { fixture_file_upload("contacts.csv", "text/csv") }

  it "stores and previews a bounded CSV" do
    csv_import = CsvImports::Create.call(admin_user:, source:)
    preview = CsvImports::Serializer.new(csv_import, include_preview: true).as_json.fetch(:preview)
    expect(preview).to include(rowCount: 2, headers: %w[first_name last_name email account])
    expect(csv_import.source).to be_attached
  end

  it "validates complete, unique, allowlisted mappings" do
    headers = %w[first last email company]
    mapping = { first: "first_name", last: "last_name", email: "email", company: "account", ignored: "" }
    expect(CsvImports::Mapping.validate!(headers:, mappings: mapping)).not_to have_key("ignored")
    expect { CsvImports::Mapping.validate!(headers:, mappings: mapping.merge(bogus: "email")) }.to raise_error(/unknown CSV header/)
    expect { CsvImports::Mapping.validate!(headers:, mappings: mapping.merge(first: "bogus")) }.to raise_error(/unknown destination/)
    expect { CsvImports::Mapping.validate!(headers:, mappings: mapping.merge(last: "first_name")) }.to raise_error(/mapped once/)
    expect { CsvImports::Mapping.validate!(headers:, mappings: mapping.except(:last)) }.to raise_error(/Map first name/)
  end

  it "rejects absent, oversized, malformed, invalid-encoding, duplicate-header, blank-header, and overlong input" do
    empty = create(:csv_import, admin_user:).tap { |item| item.source.detach }
    expect { CsvImports::Reader.new(empty).rows }.to raise_error(/Choose/)

    oversized = create(:csv_import, admin_user:)
    allow(oversized.source).to receive(:byte_size).and_return(CsvImports::Reader::MAXIMUM_BYTES + 1)
    expect { CsvImports::Reader.new(oversized).rows }.to raise_error(/100 KB/)

    [ "\"unterminated", "a,a\n1,2", "a,\n1,2", ([ "a" ] + Array.new(101, "1")).join("\n") ].each do |content|
      item = csv_import_from(content)
      expect { CsvImports::Reader.new(item).rows }.to raise_error(CsvImports::Reader::InvalidFile)
    end

    invalid = csv_import_from("name\n\xFF".b)
    expect { CsvImports::Reader.new(invalid).rows }.to raise_error(/UTF-8/)
  end

  it "deletes a rejected source and confirms once through Solid Queue" do
    expect { CsvImports::Create.call(admin_user:, source: fixture_file_upload("sample.txt", "text/plain")) }.to raise_error(CsvImports::Reader::InvalidFile)
    expect(admin_user.reload.csv_imports).to be_empty

    csv_import = CsvImports::Create.call(admin_user:, source:)
    mappings = { first_name: "first_name", last_name: "last_name", email: "email", account: "account" }
    expect { CsvImports::Confirm.call(csv_import:, mappings:) }.to have_enqueued_job(ProcessCsvImportJob).with(csv_import.id)
    expect(csv_import).to have_attributes(status: "queued", confirmed_at: be_present)
    expect { CsvImports::Confirm.call(csv_import:, mappings:) }.to raise_error(/already confirmed/)
  end

  def csv_import_from(content)
    item = create(:csv_import, admin_user:)
    item.source.attach(io: StringIO.new(content), filename: "input.csv", content_type: "text/csv")
    item
  end
end
