# app/models/ckeditor_article.rb
# frozen_string_literal: true

class CkeditorArticle < ApplicationRecord
  belongs_to :admin_user

  before_validation :sanitize_body_html

  validates :body_html, :title, presence: true
  validates :summary, length: { maximum: 180 }
  validate :body_html_within_limit

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id summary title updated_at]
  end

  private

  def sanitize_body_html
    self.body_html = Showcase::CkeditorDocument.sanitize(body_html)
  end

  def body_html_within_limit
    return unless body_html.to_s.bytesize > Showcase::CkeditorDocument::MAX_BYTES

    errors.add(:body_html, "must be 50 KB or smaller")
  end
end
