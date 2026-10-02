# spec/services/contact_archives/synthetic_inspector_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContactArchives::SyntheticInspector do
  subject(:inspector) { described_class.new }

  it "strictly parses three fictional legacy contacts without touching CRM records" do
    expect { inspector.contacts }.not_to change(Account, :count)
    expect(inspector.contacts.size).to eq(3)
    expect(inspector.archive).not_to be_sqlite
    expect(inspector.archive.diagnostics).to be_empty
    avery = inspector.contacts.find { |contact| contact.nickname == "Bluebonnet" }
    expect(avery.emails.pluck(:address)).to eq(%w[avery@example.test avery.home@example.test])
    expect(avery.addresses.first[:street]).to eq("101 Fictional Trail")
    expect(avery.notes).to include("Fictional fixture. <script>not executable</script>")
  end

  it "reports only exact email and international phone evidence without merging" do
    candidate = inspector.evidence.fetch(0)
    expect(candidate.values_at(:left, :right)).to contain_exactly('Avery "Bluebonnet" Morgan', "Avery Morgan Dispatch")
    expect(candidate[:signals].pluck(:type)).to contain_exactly(:email, :international_phone)
    expect(inspector.contacts.size).to eq(3)
  end

  it "delegates all allowed exports to the pinned upstream exporters" do
    json = JSON.parse(inspector.export("json")[:body])
    expect(json.size).to eq(3)
    expect(json.map { |contact| contact.fetch("name") }).to include("Mx. Jordan Ellis II")
    json.each { |contact| expect(contact.fetch("source")).not_to have_key("path") }
    expect(inspector.export("json")[:body]).not_to include(Rails.root.to_s)
    expect(inspector.contacts.first.source).to have_key(:path)
    expect(inspector.export("csv")[:body]).to include("avery@example.test")
    expect(inspector.export("vcf")[:body].scan("BEGIN:VCARD").size).to eq(3)
    expect(inspector.export("json")[:body]).to eq(inspector.export("json")[:body])
  end

  it "rejects unsupported formats and user paths" do
    expect { inspector.export("../../secrets") }.to raise_error(KeyError)
    expect { described_class.new(path: "/tmp/arbitrary") }.to raise_error(ArgumentError)
  end
end
