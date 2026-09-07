# app/admin/showcase_articles.rb
# frozen_string_literal: true

ActiveAdmin.register ShowcaseArticle do
  menu label: "Lexical Editor", parent: "Collaboration", priority: 10

  permit_params :editor_state, :fallback_body, :rendered_html, :summary, :title

  filter :title
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :title
    column :summary
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :title
      row :summary
      row :rendered_html do |article|
        div class: "prose max-w-none" do
          # The model stores only server-sanitized markup.
          text_node article.rendered_html.html_safe # rubocop:disable Rails/OutputSafety
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form html: { data: { turbo: false } } do |form|
    article = form.object
    editor_state = article.editor_state.presence || Showcase::LexicalDocument.empty_json

    form.semantic_errors
    form.inputs "Rails-owned fields" do
      form.input :title, hint: "Required. Submit an empty title to see editor state survive validation."
      form.input :summary, hint: "Optional plain-text context, limited to 180 characters."

      li class: "input lexical-editor-input" do
        label "Body", class: "label", for: "showcase_article_fallback_body"
        para "Lexical enhances this one field; the surrounding form and submission remain ActiveAdmin-owned."
        react_component(
          "LexicalEditor",
          props: {
            editorStateName: "showcase_article[editor_state]",
            initialHtml: article.rendered_html.to_s,
            initialState: editor_state,
            renderedHtmlName: "showcase_article[rendered_html]"
          },
          class: "mt-3"
        )
        noscript do
          para "JavaScript is unavailable. Edit the same article body as plain text; Rails will convert it safely."
          textarea article.fallback_text,
                   id: "showcase_article_fallback_body",
                   name: "showcase_article[fallback_body]",
                   rows: 12
        end
      end
    end
    form.actions

    panel "Demo" do
      para "Create or edit an article, format its body in Lexical, and submit through the ordinary ActiveAdmin form."
      para "Leave the required title blank to prove validation returns the submitted editor document intact."
    end
    panel "Ruby" do
      para "ShowcaseArticle validates the Lexical root shape, canonicalizes its JSON, and sanitizes rendered HTML."
      para "The no-JavaScript textarea enters through fallback_body and produces the same two persisted fields."
    end
    panel "JavaScript" do
      para "The application-owned LexicalEditor writes serialized editor state and rendered HTML to hidden Rails inputs."
      para "Lexical is intentionally an application dependency; activeadmin-react only mounts the island."
    end
    panel "Architecture" do
      para "Rails owns authorization, validation, persistence, sanitization, and the form contract."
      para "React owns only the rich editing interaction. No PostgreSQL, Redis, or new server-side service is required."
      para "This form uses a full Rails response for validation because activeadmin-react 0.1 does not remount islands after a Turbo 422 form replacement."
    end
  end
end
