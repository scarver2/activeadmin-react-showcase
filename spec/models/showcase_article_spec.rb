# spec/models/showcase_article_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShowcaseArticle do
  subject(:article) { build(:showcase_article) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:summary).is_at_most(180) }

  it "canonicalizes Lexical JSON and derives safe rich HTML on the server" do
    article.editor_state = JSON.generate(
      root: {
        children: [
          { children: [ { format: 1, text: "Safe", type: "text" } ], tag: "h2", type: "heading" },
          { children: [
            { children: [ { format: 10, text: "ActiveAdmin", type: "text" } ],
              type: "link", url: "https://activeadmin.info" }
          ], type: "paragraph" }
        ],
        type: "root"
      }
    )
    article.rendered_html = '<script>browser HTML is not authoritative</script>'

    expect(article).to be_valid
    expect(article.editor_state).to include('"type":"heading"', '"url":"https://activeadmin.info"')
    expect(article.rendered_html).to eq(
      '<h2><strong>Safe</strong></h2><p><a href="https://activeadmin.info" rel="nofollow noopener noreferrer">' \
      "<u><em>ActiveAdmin</em></u></a></p>"
    )
  end

  it "rejects unsafe, malformed, and protocol-relative links" do
    %w[javascript:alert(1) //evil.example ftp://files.example].each do |url|
      article.editor_state = JSON.generate(
        root: {
          children: [
            { children: [ { children: [ { text: "Unsafe", type: "text" } ], type: "link", url: } ], type: "paragraph" }
          ],
          type: "root"
        }
      )

      expect(article).not_to be_valid
      expect(article.errors[:editor_state]).to include("must be a valid Lexical document")
    end
  end

  it "accepts HTTPS, mailto, anchor, and application-relative links" do
    [ "https://activeadmin.info", "mailto:admin@example.test", "#architecture", "/admin" ].each do |url|
      article.editor_state = JSON.generate(
        root: {
          children: [
            { children: [ { children: [ { text: "Safe", type: "text" } ], type: "link", url: } ], type: "paragraph" }
          ],
          type: "root"
        }
      )

      expect(article).to be_valid
      expect(article.rendered_html).to include(%(href="#{url}"))
    end
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
    article.rendered_html = "browser value is replaced"

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

  it "rejects inline nodes directly under the root" do
    article.editor_state = JSON.generate(
      root: { children: [ { children: [ { text: "Inline", type: "text" } ], type: "link", url: "/admin" } ], type: "root" }
    )

    expect(article).not_to be_valid
  end

  it "returns an empty fallback for a legacy invalid document" do
    article.editor_state = "invalid"
    article.fallback_body = nil

    expect(article.fallback_text).to eq("")
  end
end
