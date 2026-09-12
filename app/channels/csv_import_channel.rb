# app/channels/csv_import_channel.rb
# frozen_string_literal: true

class CsvImportChannel < ApplicationCable::Channel
  def subscribed
    csv_import = current_admin_user&.csv_imports&.find_by(token: params[:token])
    return reject unless csv_import

    stream_from(csv_import.broadcast_key, coder: ActiveSupport::JSON)
    transmit({ type: "progress", import: CsvImports::Serializer.new(csv_import).as_json })
  end
end
