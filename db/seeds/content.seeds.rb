# db/seeds/content.seeds.rb
# frozen_string_literal: true

article = ShowcaseArticle.find_or_initialize_by(title: "Rich editing stays Rails-owned")
document = Showcase::LexicalDocument.from_plain_text(
  "This article is edited by Lexical and submitted through an ordinary ActiveAdmin form."
)
article.update!(
  editor_state: document.fetch(:editor_state),
  rendered_html: document.fetch(:rendered_html),
  summary: "A safe rich-text boundary demonstrated by one focused React island."
)

ShowcaseAssets::Seed.call
