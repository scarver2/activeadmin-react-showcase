# app/services/csv_imports/create.rb
# frozen_string_literal: true

module CsvImports
  class Create
    def self.call(admin_user:, source:)
      csv_import = admin_user.csv_imports.create!(token: SecureRandom.uuid)
      csv_import.source.attach(source)
      preview = Reader.new(csv_import).preview
      csv_import.update!(row_count: preview.fetch(:rowCount))
      csv_import
    rescue Reader::InvalidFile
      csv_import&.destroy!
      raise
    end
  end
end
