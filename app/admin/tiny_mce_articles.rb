# app/admin/tiny_mce_articles.rb
# frozen_string_literal: true

ActiveAdmin.register TinyMceArticle do
  menu label: "TinyMCE Editor", parent: "Collaboration", priority: 11

  scope_to :current_admin_user
  permit_params :body_html, :lock_version, :summary, :title

  controller do
    def update
      super
    rescue ActiveRecord::StaleObjectError
      resource.assign_attributes(permitted_params.fetch(:tiny_mce_article).except(:lock_version))
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
      row :body_html do |article|
        div class: "tinymce-preview", data: { testid: "tinymce-preview" } do
          # TinyMceArticle stores only markup normalized by the server allowlist.
          text_node article.body_html.html_safe # rubocop:disable Rails/OutputSafety
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |form|
    article = form.object

    form.semantic_errors
    form.input :lock_version, as: :hidden
    form.inputs "Rails-owned fields" do
      form.input :title, hint: "Required. Submit an empty title to prove the enhanced textarea survives validation."
      form.input :summary, hint: "Optional plain-text context, limited to 180 characters."

      li class: "input tinymce-editor-input" do
        label "Body", class: "label", for: "tiny_mce_article_body_html"
        para "TinyMCE enhances this textarea; Rails still owns submission, validation, sanitization, and persistence."
        textarea article.body_html,
                 id: "tiny_mce_article_body_html",
                 name: "tiny_mce_article[body_html]",
                 rows: 18
        react_component(
          "TinyMceEditor",
          props: { textareaId: "tiny_mce_article_body_html" },
          class: "mt-3"
        )
        if article.errors[:body_html].any?
          ul class: "tinymce-errors", role: "alert" do
            article.errors.full_messages_for(:body_html).each { |message| li message }
          end
        end
      end
    end
    form.actions

    panel "Demo" do
      para "Edit headings, emphasis, lists, links, quotes, and code with a self-hosted TinyMCE build."
      para "Disable JavaScript and the same field remains a conventional HTML textarea."
    end
    panel "Ruby" do
      para "TinyMceArticle scopes records to the signed-in administrator and sanitizes every submission through a narrow tag and attribute allowlist."
      para "Scripts, embeds, images, inline styles, event handlers, and unsafe link protocols are not persisted."
    end
    panel "JavaScript" do
      para "The React island owns only TinyMCE setup and teardown around the existing Rails textarea."
      para "The GPL package is bundled locally: no cloud key, paid plugin, telemetry endpoint, or CDN is involved."
    end
    panel "Architecture" do
      para "Rails owns authorization, validation, persistence, sanitization, and media policy. TinyMCE owns the editing interaction."
      para "Uploads stay in the Rails-owned Asset Manager; this experiment intentionally exposes no image or media insertion command."
    end
  end
end
