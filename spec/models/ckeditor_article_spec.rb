# spec/models/ckeditor_article_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe CkeditorArticle do
  subject(:article) { build(:ckeditor_article) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:summary).is_at_most(180) }

  it "persists only the bounded server-sanitized vocabulary" do
    article.body_html = <<~HTML
      <h2>Briefing</h2>
      <p onclick="alert(1)"><strong>Keep</strong> this <em>meaning</em>.</p>
      <script>alert(1)</script><iframe src="https://example.test"></iframe>
      <a href="javascript:alert(1)" style="color:red">Unsafe link</a>
    HTML

    expect(article).to be_valid
    expect(article.body_html).to include("<h2>Briefing</h2>", "<strong>Keep</strong>", "<em>meaning</em>")
    expect(article.body_html).not_to include("onclick", "<script", "<iframe", "javascript:", "style=")
  end

  it "keeps safe links and removes unapproved attributes" do
    article.body_html = '<p><a href="https://activeadmin.info" title="ActiveAdmin" target="_blank">Project</a></p>'

    expect(article).to be_valid
    expect(article.body_html).to eq('<p><a href="https://activeadmin.info" title="ActiveAdmin">Project</a></p>')
  end

  it "rejects empty and oversized sanitized documents" do
    article.body_html = "<script></script>"
    expect(article).not_to be_valid
    expect(article.errors[:body_html]).to include("can't be blank")

    article.body_html = "<p>#{'x' * Showcase::CkeditorDocument::MAX_BYTES}</p>"
    expect(article).not_to be_valid
    expect(article.errors[:body_html]).to include("must be 50 KB or smaller")
  end
end
