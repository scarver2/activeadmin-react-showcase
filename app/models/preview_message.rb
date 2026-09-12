# app/models/preview_message.rb
# frozen_string_literal: true

class PreviewMessage < ApplicationRecord
  ALLOWED_TYPES = %w[application/pdf application/vnd.openxmlformats-officedocument.wordprocessingml.document image/jpeg image/png].freeze
  MAXIMUM_BYTES = 2.megabytes

  has_many_attached :attachments
  validates :recipient, :sender, :subject, :text_body, presence: true
end
