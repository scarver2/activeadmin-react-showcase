# app/models/content_document.rb
# frozen_string_literal: true

class ContentDocument < ApplicationRecord
  belongs_to :admin_user
  has_many :content_blocks, -> { order(:position) }, dependent: :destroy, inverse_of: :content_document
  validates :title, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id created_at id lock_version title updated_at]
  end
end
