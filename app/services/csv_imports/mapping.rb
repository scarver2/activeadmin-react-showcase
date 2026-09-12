# app/services/csv_imports/mapping.rb
# frozen_string_literal: true

module CsvImports
  class Mapping
    FIELDS = %w[first_name last_name email account].freeze

    class InvalidMapping < StandardError; end

    def self.validate!(headers:, mappings:)
      normalized = mappings.to_h.transform_keys(&:to_s).transform_values(&:to_s).select { |_header, field| field.present? }
      unknown_headers = normalized.keys - headers
      unknown_fields = normalized.values - FIELDS
      raise InvalidMapping, "Mapping contains an unknown CSV header" if unknown_headers.any?
      raise InvalidMapping, "Mapping contains an unknown destination field" if unknown_fields.any?
      raise InvalidMapping, "Each destination field may be mapped once" if normalized.values.uniq.length != normalized.values.length
      raise InvalidMapping, "Map first name, last name, email, and account" unless (FIELDS - normalized.values).empty?

      normalized
    end
  end
end
