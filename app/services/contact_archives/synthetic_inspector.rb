# app/services/contact_archives/synthetic_inspector.rb
# frozen_string_literal: true

require "tempfile"

module ContactArchives
  # Reads only the committed fictional bundle. Never accepts a filesystem path or upload.
  class SyntheticInspector
    REVISION = "77eaedaeb0e5d328957c53df7dd5d04134cd4ffa"
    EXPORTERS = {
      "csv" => [ Abbu::Exporters::CsvExporter, "text/csv" ],
      "json" => [ Abbu::Exporters::JsonExporter, "application/json" ],
      "vcf" => [ Abbu::Exporters::VcardExporter, "text/vcard" ]
    }.freeze

    def archive
      @archive ||= Abbu.open(Rails.root.join("data/contact_archives/Northstar.abbu"), strict: true)
    end

    def contacts
      archive.contacts
    end

    def evidence
      Abbu::Utils::Deduplicator.new(contacts).matches.filter_map do |match|
        exact = match.evidence.select { |item| item[:type].in?(%i[email international_phone]) }
        next if exact.empty?

        { left: match.left.full_name, right: match.right.full_name, signals: exact }
      end
    end

    def export(format)
      exporter, content_type = EXPORTERS.fetch(format)
      Tempfile.create([ "showcase-synthetic-contacts", ".#{format}" ]) do |file|
        exporter.new(export_contacts).to_file(file.path)
        { body: File.binread(file.path), content_type: content_type, filename: "northstar-synthetic.#{format}" }
      end
    end

    private

    def export_contacts
      contacts.map do |contact|
        contact.dup.tap { |copy| copy.source = contact.source.except(:path) }
      end
    end
  end
end
