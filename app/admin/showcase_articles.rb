# app/admin/showcase_articles.rb
# frozen_string_literal: true

ActiveAdmin.register ShowcaseArticle do
  menu label: "Lexical Editor", parent: "Collaboration", priority: 10

  permit_params :editor_state, :fallback_body, :lock_version, :summary, :title

  controller do
    def update
      super
    rescue ActiveRecord::StaleObjectError
      resource.assign_attributes(permitted_params.fetch(:showcase_article).except(:lock_version))
      resource.lock_version = resource.class.where(id: resource.id).pick(:lock_version)
      resource.errors.add(:base, "This article changed in another session. Your draft is preserved; review it before saving again.")
      render :edit, status: :conflict
    end
  end

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
    form.input :lock_version, as: :hidden
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
            initialState: editor_state
          },
          class: "mt-3"
        )
        if article.errors[:editor_state].any?
          ul class: "lexical-errors", role: "alert" do
            article.errors.full_messages_for(:editor_state).each { |message| li message }
          end
        end
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
      para "Create or edit an article with headings, lists, quotes, links, and familiar inline formatting."
      para "Validation and stale-write responses preserve the submitted document so an administrator never loses a draft."
    end
    panel "Ruby" do
      para "ShowcaseArticle validates canonical Lexical JSON, rejects unsafe link protocols, and renders safe HTML itself."
      para "The no-JavaScript textarea enters through fallback_body and produces the same two persisted fields."
    end
    panel "JavaScript" do
      para "The application-owned LexicalEditor writes only serialized editor state to the Rails form."
      para "Lexical is intentionally an application dependency; activeadmin-react only mounts the island."
    end
    panel "Architecture" do
      para "Rails owns authorization, validation, persistence, sanitization, and the form contract."
      para "React owns only the rich editing interaction; browser-produced HTML is never a trusted persistence input."
      para "This form uses a full Rails response for validation because activeadmin-react 0.1 does not remount islands after a Turbo 422 form replacement."
    end
  end
end
