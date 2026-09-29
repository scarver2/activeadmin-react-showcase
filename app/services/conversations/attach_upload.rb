# app/services/conversations/attach_upload.rb
# frozen_string_literal: true

module Conversations
  class AttachUpload
    CONTENT_TYPE_EXTENSIONS = {
      "image/jpeg" => ".jpg",
      "image/png" => ".png",
      "text/plain" => ".txt"
    }.freeze

    class InvalidUpload < StandardError; end

    def self.call(message:, upload:)
      new(message:, upload:).call
    end

    def self.cleanup(attachment)
      blob = attachment&.file&.blob
      return if blob.nil?

      blob.service.delete(blob.key)
      blob.destroy if blob.persisted?
    rescue ActiveStorage::FileNotFoundError
      blob.destroy if blob.persisted?
    end

    def initialize(message:, upload:)
      @message = message
      @upload = upload
    end

    def call
      validate_upload!
      attachment = MessageAttachment.new(conversation: @message.conversation, message: @message)
      attachment.file.attach(
        content_type: @detected_content_type,
        filename: sanitized_filename,
        io: @upload.tempfile
      )
      attachment.save!
      attachment
    rescue StandardError
      self.class.cleanup(attachment)
      raise
    end

    private

    def detected_content_type
      @upload.tempfile.rewind
      Marcel::MimeType.for(@upload.tempfile, name: @upload.original_filename, declared_type: @upload.content_type)
    ensure
      @upload.tempfile.rewind
    end

    def sanitized_filename
      original = File.basename(@upload.original_filename.to_s)
      stem = File.basename(original, ".*").gsub(/[^0-9A-Za-z._-]+/, "-").gsub(/\A[-.]+|[-.]+\z/, "")
      stem = "attachment" if stem.blank?
      "#{stem.first(80)}#{CONTENT_TYPE_EXTENSIONS.fetch(@detected_content_type)}"
    end

    def validate_upload!
      raise InvalidUpload, "Attachment is missing." unless @upload.respond_to?(:tempfile)
      raise InvalidUpload, "Attachment must be 1 MB or smaller." if @upload.size > MessageAttachment::MAXIMUM_BYTES

      @detected_content_type = detected_content_type
      return if @detected_content_type.in?(MessageAttachment::ALLOWED_CONTENT_TYPES)

      raise InvalidUpload, "Attachment type is not allowed. Use PNG, JPEG, or plain text."
    end
  end
end
