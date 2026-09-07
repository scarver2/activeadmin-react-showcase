# spec/requests/showcase_articles_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Showcase articles" do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  it "renders the Rails form, React mount contract, fallback, and implementation guidance" do
    get new_admin_showcase_article_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.css('[data-react-component="LexicalEditor"]').size).to eq(1)
    expect(response.parsed_body.at_css("form")[:"data-turbo"]).to eq("false")
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
        rendered_html: '<p>Unlost <strong onclick="unsafe()">draft</strong></p>',
        summary: "Validation demonstration",
        title: ""
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Unlost draft")
    expect(response.body).to include("Unlost &lt;strong&gt;draft&lt;/strong&gt;")
    expect(response.body).not_to include("onclick")
  end
end
