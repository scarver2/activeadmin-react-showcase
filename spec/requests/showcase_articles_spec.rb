# spec/requests/showcase_articles_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Showcase articles" do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  it "requires an authenticated administrator" do
    sign_out admin

    get new_admin_showcase_article_path

    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "renders the Rails form, React mount contract, fallback, and implementation guidance" do
    get new_admin_showcase_article_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css('[data-react-component="LexicalEditor"]').size).to eq(1)
    article_form = response.parsed_body.css("form").find { |form| form["action"] == admin_showcase_articles_path }
    expect(article_form[:"data-turbo"]).to eq("false")
    expect(response.body).to include("showcase_article[fallback_body]")
    expect(response.body).to include("Demo", "Ruby", "JavaScript", "Architecture")
  end

  it "creates an article from the no-JavaScript fallback" do
    expect do
      post admin_showcase_articles_path, params: {
        showcase_article: {
          fallback_body: "Plain <script>fallback</script>",
          summary: "No JavaScript required",
          title: "Fallback article"
        }
      }
    end.to change(ShowcaseArticle, :count).by(1)

    article = ShowcaseArticle.last
    expect(response).to redirect_to(admin_showcase_article_path(article))
    expect(article.rendered_html).to eq("<p>Plain &lt;script&gt;fallback&lt;/script&gt;</p>")
  end

  it "updates and explicitly clears an article through the no-JavaScript field" do
    article = create(:showcase_article)

    patch admin_showcase_article_path(article), params: {
      showcase_article: {
        fallback_body: "First line\nSecond paragraph",
        summary: article.summary,
        title: article.title
      }
    }

    expect(response).to redirect_to(admin_showcase_article_path(article))
    expect(article.reload.rendered_html).to eq("<p>First line</p><p>Second paragraph</p>")
    expect(article.fallback_text).to eq("First line\nSecond paragraph")

    patch admin_showcase_article_path(article), params: {
      showcase_article: { fallback_body: "", summary: article.summary, title: article.title }
    }

    expect(response).to redirect_to(admin_showcase_article_path(article))
    expect(article.reload.rendered_html).to eq("<p></p>")
    expect(article.fallback_text).to eq("")
    expect(JSON.parse(article.editor_state).dig("root", "children", 0, "type")).to eq("paragraph")
  end

  it "round-trips editor state and HTML when ordinary Rails validation fails" do
    state = Showcase::LexicalDocument.from_plain_text("Unlost draft").fetch(:editor_state)

    post admin_showcase_articles_path, params: {
      showcase_article: {
        editor_state: state,
        summary: "Validation demonstration",
        title: ""
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Unlost draft")
  end

  it "rejects an unsafe link without losing the submitted document" do
    state = JSON.generate(
      root: {
        children: [
          { children: [
            { children: [ { text: "Keep this rejected link", type: "text" } ], type: "link", url: "javascript:alert(1)" }
          ], type: "paragraph" }
        ],
        type: "root"
      }
    )

    post admin_showcase_articles_path, params: {
      showcase_article: { editor_state: state, summary: "Unsafe link", title: "Rejected link" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Keep this rejected link", "Editor state must be a valid Lexical document")
    expect(ShowcaseArticle.find_by(title: "Rejected link")).to be_nil
  end

  it "returns a conflict and preserves the draft after a stale write" do
    article = create(:showcase_article)
    stale_version = article.lock_version
    article.update!(summary: "Changed elsewhere")
    state = Showcase::LexicalDocument.from_plain_text("Unsaved stale draft").fetch(:editor_state)

    patch admin_showcase_article_path(article), params: {
      showcase_article: {
        editor_state: state,
        lock_version: stale_version,
        summary: "My draft",
        title: article.title
      }
    }

    expect(response).to have_http_status(:conflict)
    expect(response.body).to include("Unsaved stale draft", "changed in another session")
    expect(article.reload.summary).to eq("Changed elsewhere")

    refreshed_version = response.parsed_body.at_css("#showcase_article_lock_version")["value"]
    patch admin_showcase_article_path(article), params: {
      showcase_article: {
        editor_state: state,
        lock_version: refreshed_version,
        summary: "My reviewed draft",
        title: article.title
      }
    }

    expect(response).to redirect_to(admin_showcase_article_path(article))
    expect(article.reload.summary).to eq("My reviewed draft")
    expect(article.rendered_html).to include("Unsaved stale draft")
  end
end
