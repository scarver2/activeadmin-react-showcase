# app/services/csv_imports/confirm.rb
# frozen_string_literal: true

module CsvImports
  class Confirm
    class AlreadyConfirmed < StandardError; end

    def self.call(csv_import:, mappings:)
      csv_import.with_lock do
        raise AlreadyConfirmed, "Import was already confirmed" unless csv_import.status == "draft"

        headers = Reader.new(csv_import).rows.headers
        csv_import.mappings = Mapping.validate!(headers:, mappings:)
        csv_import.update!(confirmed_at: Time.current, status: "queued")
        ProcessCsvImportJob.perform_later(csv_import.id)
      end
      csv_import
    end
  end
end
