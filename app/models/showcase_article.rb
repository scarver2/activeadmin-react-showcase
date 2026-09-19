# app/models/showcase_article.rb
# frozen_string_literal: true

class ShowcaseArticle < ApplicationRecord
  attr_accessor :fallback_body

  before_validation :apply_fallback_body
  before_validation :normalize_and_render_document

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
    return fallback_body unless fallback_body.nil?

    Showcase::LexicalDocument.to_plain_text(editor_state)
  rescue Showcase::LexicalDocument::InvalidDocument
    ""
  end

  private

  def apply_fallback_body
    return if fallback_body.nil?

    document = Showcase::LexicalDocument.from_plain_text(fallback_body)
    self.editor_state = document.fetch(:editor_state)
  end

  def editor_state_must_be_a_lexical_document
    Showcase::LexicalDocument.normalize(editor_state)
  rescue Showcase::LexicalDocument::InvalidDocument
    errors.add(:editor_state, "must be a valid Lexical document")
  end

  def normalize_and_render_document
    self.editor_state = Showcase::LexicalDocument.normalize(editor_state)
    self.rendered_html = Showcase::LexicalDocument.render_html(editor_state)
  rescue Showcase::LexicalDocument::InvalidDocument
    self.rendered_html = ""
  end
end
