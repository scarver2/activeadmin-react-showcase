# app/models/csv_import.rb
# frozen_string_literal: true

class CsvImport < ApplicationRecord
  STATUSES = %w[draft queued processing completed failed].freeze

  belongs_to :admin_user
  has_many :csv_import_rows, dependent: :destroy
  has_one_attached :source

  validates :status, inclusion: { in: STATUSES }
  validates :token, presence: true, uniqueness: true

  def mappings
    JSON.parse(mappings_json)
  end

  def mappings=(value)
    self.mappings_json = value.to_h.to_json
  end

  def row_errors
    JSON.parse(errors_json)
  end

  def row_errors=(value)
    self.errors_json = Array(value).to_json
  end

  def broadcast_key
    "csv_import:#{token}"
  end

  def self.ransackable_associations(_auth_object = nil)
    [ "admin_user" ]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id confirmed_at created_at failed_rows id imported_rows processed_rows row_count status token]
  end
end
