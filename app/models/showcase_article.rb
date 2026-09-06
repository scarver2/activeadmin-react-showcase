# app/models/showcase_article.rb
# frozen_string_literal: true

class ShowcaseArticle < ApplicationRecord
  attr_accessor :fallback_body

  before_validation :apply_fallback_body
  before_validation :normalize_editor_state
  before_validation :sanitize_rendered_html

  validates :editor_state, :rendered_html, :title, presence: true
  validates :summary, length: { maximum: 180 }
  validate :editor_state_must_be_a_lexical_document

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id summary title updated_at]
  end

  def fallback_text
    fallback_body.presence || ActionView::Base.full_sanitizer.sanitize(rendered_html.to_s)
  end

  private

  def apply_fallback_body
    return if fallback_body.blank?

    document = Showcase::LexicalDocument.from_plain_text(fallback_body)
    self.editor_state = document.fetch(:editor_state)
    self.rendered_html = document.fetch(:rendered_html)
  end

  def editor_state_must_be_a_lexical_document
    Showcase::LexicalDocument.normalize(editor_state)
  rescue Showcase::LexicalDocument::InvalidDocument
    errors.add(:editor_state, "must be a valid Lexical document")
  end

  def normalize_editor_state
    self.editor_state = Showcase::LexicalDocument.normalize(editor_state)
  rescue Showcase::LexicalDocument::InvalidDocument
    nil
  end

  def sanitize_rendered_html
    self.rendered_html = Showcase::LexicalDocument.sanitize_html(rendered_html)
  end
end
