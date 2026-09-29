# config/initializers/conversation_attachment_active_storage.rb
# frozen_string_literal: true

# Active Storage's built-in signed blob and representation routes are public by
# design. Conversation files instead require a current membership check through
# Admin::ConversationAttachmentsController, so the public resolvers must never
# resolve a blob used by MessageAttachment.
module ConversationAttachmentActiveStorageBoundary
  private

  def blob_scope
    conversation_blob_ids = ActiveStorage::Attachment.where(record_type: "MessageAttachment").select(:blob_id)
    super.where.not(id: conversation_blob_ids)
  end
end

Rails.application.config.to_prepare do
  guarded_controllers = [
    ActiveStorage::Blobs::ProxyController,
    ActiveStorage::Blobs::RedirectController,
    ActiveStorage::Representations::BaseController
  ]
  guarded_controllers.each do |controller|
    controller.prepend(ConversationAttachmentActiveStorageBoundary) unless
      controller < ConversationAttachmentActiveStorageBoundary
  end
end
