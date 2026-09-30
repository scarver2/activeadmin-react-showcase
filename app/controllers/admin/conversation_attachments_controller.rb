# app/controllers/admin/conversation_attachments_controller.rb
# frozen_string_literal: true

module Admin
  class ConversationAttachmentsController < ConversationBaseController
    before_action :load_message

    def show
      raise ActiveRecord::RecordNotFound if @message.withdrawn?

      attachment = @message.attachment
      raise ActiveRecord::RecordNotFound if attachment.nil? || attachment.public_id != params[:attachment_public_id]

      response.set_header("Content-Security-Policy", "default-src 'none'; sandbox")
      response.set_header("X-Content-Type-Options", "nosniff")
      send_data attachment.file.download,
                disposition: attachment.inline? ? "inline" : "attachment",
                filename: attachment.file.filename.to_s,
                type: attachment.file.content_type
    end
  end
end
