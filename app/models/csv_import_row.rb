# app/models/csv_import_row.rb
# frozen_string_literal: true

class CsvImportRow < ApplicationRecord
  belongs_to :contact, optional: true
  belongs_to :csv_import

  validates :row_number, uniqueness: { scope: :csv_import_id }
  validates :status, inclusion: { in: %w[pending imported failed] }
end
