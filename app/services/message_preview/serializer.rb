# app/services/message_preview/serializer.rb
# frozen_string_literal: true

module MessagePreview
  class Serializer
    def initialize(message) = @message = message

    def as_json
      { id: @message.id, subject: @message.subject, recipient: @message.recipient, sender: @message.sender,
        htmlBody: ApplicationController.helpers.sanitize(@message.html_body), textBody: @message.text_body,
        attachments: @message.attachments.filter_map { |attachment| serialize_attachment(attachment) } }
    end

    private

    def serialize_attachment(attachment)
      return unless PreviewMessage::ALLOWED_TYPES.include?(attachment.content_type)
      return { id: attachment.id, filename: attachment.filename.to_s, kind: "oversized", size: attachment.byte_size } if attachment.byte_size > PreviewMessage::MAXIMUM_BYTES

      kind = if attachment.image? then "image" elsif attachment.content_type == "application/pdf" then "pdf" else "download" end
      { id: attachment.id, filename: attachment.filename.to_s, kind:, size: attachment.byte_size,
        url: Rails.application.routes.url_helpers.rails_blob_path(attachment, disposition: kind == "download" ? "attachment" : "inline", only_path: true) }
    end
  end
end
