# spec/models/tiny_mce_article_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe TinyMceArticle do
  subject(:article) { build(:tiny_mce_article) }

  it { is_expected.to belong_to(:admin_user) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:summary).is_at_most(180) }

  it "preserves the bounded rich-text vocabulary" do
    article.body_html = <<~HTML
      <h2>Briefing</h2><p><strong>Strong</strong> and <em>emphasized</em>.</p>
      <ul><li>One</li></ul><ol><li>Two</li></ol>
      <blockquote>Rails remains authoritative.</blockquote>
      <pre><code>status = :ready</code></pre>
      <p><a href="https://activeadmin.info" title="ActiveAdmin">Reference</a></p>
    HTML

    expect(article).to be_valid
    expect(article.body_html).to include("<h2>Briefing</h2>", "<blockquote>", "<pre><code>")
    expect(article.body_html).to include('href="https://activeadmin.info"', 'title="ActiveAdmin"')
  end

  it "removes active content, embeds, media, styles, event handlers, and unsafe protocols" do
    article.body_html = <<~HTML
      <script>alert(1)</script>
      <p style="color:red" onclick="alert(1)">Keep this sentence.</p>
      <iframe src="https://example.test"></iframe><img src="data:image/png;base64,unsafe">
      <video src="https://example.test/movie.mp4"></video>
      <a href="javascript:alert(1)" target="_blank">Unsafe link</a>
    HTML

    expect(article).to be_valid
    expect(article.body_html).to include("Keep this sentence.", "Unsafe link")
    expect(article.body_html).not_to include("<script", "<iframe", "<img", "<video", "style=", "onclick=", "javascript:", "target=")
  end

  it "rejects an empty document after sanitization" do
    article.body_html = '<img src="data:image/png;base64,unsafe">'

    expect(article).not_to be_valid
    expect(article.errors[:body_html]).to include("can't be blank")
  end

  it "rejects documents larger than the bounded server contract" do
    article.body_html = "<p>#{'x' * Showcase::TinyMceDocument::MAX_BYTES}</p>"

    expect(article).not_to be_valid
    expect(article.errors[:body_html]).to include("must be 50 KB or smaller")
  end
end
