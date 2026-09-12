# app/jobs/process_csv_import_job.rb
# frozen_string_literal: true

class ProcessCsvImportJob < ApplicationJob
  queue_as :default

  def perform(csv_import_id)
    csv_import = CsvImport.find(csv_import_id)
    return if csv_import.status == "completed"

    csv_import.update!(status: "processing")
    CsvImports::Reader.new(csv_import).rows.each.with_index(2) { |row, number| process_row(csv_import, row, number) }
    csv_import.update!(status: "completed")
    broadcast(csv_import)
  rescue StandardError => e
    csv_import&.update!(status: "failed", row_errors: [ e.message ])
    broadcast(csv_import) if csv_import&.persisted?
    raise
  end

  private

  def process_row(csv_import, row, number)
    marker = csv_import.csv_import_rows.find_or_initialize_by(row_number: number)
    return unless marker.new_record? || marker.status == "pending"

    attributes = csv_import.mappings.to_h { |header, field| [ field, row[header].to_s.strip ] }
    account = Account.find_by(name: attributes.fetch("account"))
    contact = Contact.find_or_initialize_by(email: attributes.fetch("email"))
    contact.assign_attributes(
      account:, first_name: attributes.fetch("first_name"), last_name: attributes.fetch("last_name"),
      job_title: "Imported contact", relationship_role: "Operations lead"
    )
    contact.save!
    marker.update!(contact:, status: "imported")
  rescue ActiveRecord::RecordInvalid, KeyError => e
    marker.update!(error: e.message, status: "failed")
  ensure
    refresh_progress(csv_import) if marker&.persisted?
  end

  def refresh_progress(csv_import)
    csv_import.update!(
      processed_rows: csv_import.csv_import_rows.count,
      imported_rows: csv_import.csv_import_rows.where(status: "imported").count,
      failed_rows: csv_import.csv_import_rows.where(status: "failed").count,
      row_errors: csv_import.csv_import_rows.where(status: "failed").order(:row_number).limit(20).pluck(:error)
    )
    broadcast(csv_import)
  end

  def broadcast(csv_import)
    ActionCable.server.broadcast(
      csv_import.broadcast_key,
      { type: "progress", import: CsvImports::Serializer.new(csv_import).as_json }
    )
  end
end
