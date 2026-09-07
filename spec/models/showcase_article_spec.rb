# spec/models/showcase_article_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowcaseArticle do
  subject(:article) { build(:showcase_article) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:summary).is_at_most(180) }

  it "canonicalizes valid Lexical JSON and sanitizes rendered HTML" do
    article.editor_state = <<~JSON
      { "root": { "type": "root", "children": [{ "type": "paragraph", "children": [] }], "version": 1 } }
    JSON
    article.rendered_html = '<p onclick="steal()"><strong>Safe</strong><script>unsafe()</script></p>'

    expect(article).to be_valid
    expect(article.editor_state).to eq(
      '{"root":{"type":"root","children":[{"type":"paragraph","children":[]}],"version":1}}'
    )
    expect(article.rendered_html).to eq("<p><strong>Safe</strong>unsafe()</p>")
  end

  it "rejects malformed JSON and non-Lexical document roots" do
    article.editor_state = "not JSON"
    expect(article).not_to be_valid
    expect(article.errors[:editor_state]).to include("must be a valid Lexical document")

    article.editor_state = '{"root":{"type":"paragraph","children":[]}}'
    expect(article).not_to be_valid
    expect(article.errors[:editor_state]).to include("must be a valid Lexical document")
  end

  it "rejects unknown nodes and oversized editor payloads" do
    article.editor_state = '{"root":{"type":"root","children":[{"type":"script"}]}}'
    expect(article).not_to be_valid

    article.editor_state = " " * (Showcase::LexicalDocument::MAX_JSON_BYTES + 1)
    expect(article).not_to be_valid
    expect(article.errors[:editor_state]).to include("must be a valid Lexical document")
  end

  it "converts and escapes the no-JavaScript fallback through the same persistence fields" do
    article.editor_state = nil
    article.fallback_body = "First line\n<script>unsafe()</script>"
    article.rendered_html = nil

    expect(article).to be_valid
    expect(article.editor_state).to include("First line", "<script>unsafe()</script>")
    expect(article.rendered_html).to eq("<p>First line</p><p>&lt;script&gt;unsafe()&lt;/script&gt;</p>")
    expect(article.fallback_text).to eq(article.fallback_body)
  end

  it "preserves paragraph and line-break semantics in fallback text" do
    article.fallback_body = nil
    article.editor_state = JSON.generate(
      root: {
        children: [
          { children: [ { text: "First", type: "text" }, { type: "linebreak" }, { text: "line", type: "text" } ],
            type: "paragraph" },
          { children: [ { text: "Second paragraph", type: "text" } ], type: "paragraph" }
        ],
        type: "root"
      }
    )

    expect(article.fallback_text).to eq("First\nline\nSecond paragraph")
  end

  it "provides a structurally editable empty Lexical document" do
    document = JSON.parse(Showcase::LexicalDocument.empty_json)

    expect(document.dig("root", "children", 0, "type")).to eq("paragraph")
  end

  it "rejects a root without an editable child" do
    article.editor_state = '{"root":{"children":[],"type":"root"}}'

    expect(article).not_to be_valid
    expect(article.errors[:editor_state]).to include("must be a valid Lexical document")
  end

  it "returns an empty fallback for a legacy invalid document" do
    article.editor_state = "invalid"
    article.fallback_body = nil

    expect(article.fallback_text).to eq("")
  end
end
