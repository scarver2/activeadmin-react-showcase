# app/models/content_block.rb
# frozen_string_literal: true

class ContentBlock < ApplicationRecord
  TYPES = %w[callout heading paragraph].freeze
  belongs_to :content_document
  validates :block_type, inclusion: { in: TYPES }
  validates :body, presence: true, length: { maximum: 500 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[block_type body content_document_id created_at id position updated_at]
  end
end
