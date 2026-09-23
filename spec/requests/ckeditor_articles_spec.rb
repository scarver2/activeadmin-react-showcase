# spec/requests/ckeditor_articles_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CKEditor articles" do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  it "requires an authenticated administrator" do
    sign_out admin

    get new_admin_ckeditor_article_path

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "renders one enhancement island over a meaningful textarea fallback" do
    get new_admin_ckeditor_article_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css('[data-react-component="CkeditorEditor"]').size).to eq(1)
    expect(response.parsed_body.at_css("textarea#ckeditor_article_body_html")["name"]).to eq("ckeditor_article[body_html]")
    expect(response.body).to include("Demo", "Ruby", "JavaScript", "Architecture")
    expect(response.body).to include("no cloud service", "no image, media, CKBox, CKFinder, or upload adapter")
  end

  it "creates an owned article and persists only server-sanitized markup" do
    expect do
      post admin_ckeditor_articles_path, params: {
        ckeditor_article: {
          body_html: '<h2>Briefing</h2><p onclick="alert(1)">Keep me</p><script>alert(1)</script>',
          summary: "Safe preview",
          title: "Sanitized CKEditor article"
        }
      }
    end.to change(admin.ckeditor_articles, :count).by(1)

    article = admin.ckeditor_articles.last
    expect(response).to redirect_to(admin_ckeditor_article_path(article))
    expect(article.body_html).to eq("<h2>Briefing</h2><p>Keep me</p>alert(1)")
  end

  it "preserves submitted editor content when Rails validation fails" do
    post admin_ckeditor_articles_path, params: {
      ckeditor_article: {
        body_html: "<h2>Unlost draft</h2><p>Still here after validation.</p>",
        summary: "Validation proof",
        title: ""
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Unlost draft", "Still here after validation")
    expect(CkeditorArticle.find_by(summary: "Validation proof")).to be_nil
  end

  it "prevents administrators from reading or changing another administrator's article" do
    other_article = create(:ckeditor_article)

    get admin_ckeditor_article_path(other_article)
    expect(response).to have_http_status(:not_found)

    patch admin_ckeditor_article_path(other_article), params: {
      ckeditor_article: { body_html: "<p>Unauthorized</p>", title: "Unauthorized" }
    }
    expect(response).to have_http_status(:redirect)
    expect(other_article.reload.title).not_to eq("Unauthorized")
  end

  it "returns a conflict without losing a stale editor draft" do
    article = create(:ckeditor_article, admin_user: admin)
    stale_version = article.lock_version
    article.update!(summary: "Changed elsewhere")

    patch admin_ckeditor_article_path(article), params: {
      ckeditor_article: {
        body_html: "<h2>Unsaved stale draft</h2>",
        lock_version: stale_version,
        summary: "My draft",
        title: article.title
      }
    }

    expect(response).to have_http_status(:conflict)
    expect(response.body).to include("Unsaved stale draft", "changed in another session")
    expect(article.reload.summary).to eq("Changed elsewhere")
  end
end
