# app/services/csv_imports/serializer.rb
# frozen_string_literal: true

module CsvImports
  class Serializer
    def initialize(csv_import, include_preview: false)
      @csv_import = csv_import
      @include_preview = include_preview
    end

    def as_json(*)
      result = {
        token: csv_import.token, status: csv_import.status, rowCount: csv_import.row_count,
        processedRows: csv_import.processed_rows, importedRows: csv_import.imported_rows,
        failedRows: csv_import.failed_rows, mappings: csv_import.mappings, errors: csv_import.row_errors
      }
      result[:preview] = Reader.new(csv_import).preview if include_preview
      result
    end

    private

    attr_reader :csv_import, :include_preview
  end
end
