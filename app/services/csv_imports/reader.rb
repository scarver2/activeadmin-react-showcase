# app/services/csv_imports/reader.rb
# frozen_string_literal: true

require "csv"

module CsvImports
  class Reader
    MAXIMUM_BYTES = 100.kilobytes
    MAXIMUM_ROWS = 100
    PREVIEW_ROWS = 5

    class InvalidFile < StandardError; end

    def initialize(csv_import)
      @csv_import = csv_import
    end

    def rows
      raise InvalidFile, "Choose a CSV file" unless csv_import.source.attached?
      raise InvalidFile, "CSV exceeds 100 KB" if csv_import.source.byte_size > MAXIMUM_BYTES

      content = csv_import.source.download
      raise InvalidFile, "CSV must be valid UTF-8" unless content.force_encoding(Encoding::UTF_8).valid_encoding?

      table = CSV.parse(content, headers: true)
      headers = Array(table.headers).map { |header| header.to_s.strip }
      raise InvalidFile, "CSV needs a header row" if headers.empty? || headers.any?(&:blank?)
      raise InvalidFile, "CSV headers must be unique" if headers.uniq.length != headers.length
      raise InvalidFile, "CSV needs at least one data row" if table.empty?
      raise InvalidFile, "CSV exceeds 100 rows" if table.length > MAXIMUM_ROWS

      table
    rescue CSV::MalformedCSVError => e
      raise InvalidFile, "Malformed CSV: #{e.message}"
    end

    def preview
      table = rows
      { headers: table.headers, rows: table.first(PREVIEW_ROWS).map(&:to_h), rowCount: table.length }
    end

    private

    attr_reader :csv_import
  end
end
