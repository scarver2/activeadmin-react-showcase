# spec/factories/showcase_articles.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :showcase_article do
    sequence(:title) { |number| "Lexical article #{number}" }
    editor_state { Showcase::LexicalDocument.from_plain_text("A Rails-owned document").fetch(:editor_state) }
    rendered_html { "<p>A Rails-owned document</p>" }
    summary { "A concise description owned by the ordinary Rails form." }
  end
end
