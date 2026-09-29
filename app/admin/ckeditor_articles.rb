# app/admin/ckeditor_articles.rb
# frozen_string_literal: true

ActiveAdmin.register CkeditorArticle do
  menu label: "CKEditor 5", parent: "Collaboration", priority: 12

  scope_to :current_admin_user
  permit_params :body_html, :lock_version, :summary, :title

  controller do
    def update
      super
    rescue ActiveRecord::StaleObjectError
      resource.assign_attributes(permitted_params.fetch(:ckeditor_article).except(:lock_version))
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
        div class: "ckeditor-preview prose max-w-none", data: { testid: "ckeditor-preview" } do
          # CkeditorArticle stores only markup normalized by the server allowlist.
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

      li class: "input ckeditor-editor-input" do
        label "Body", class: "label", for: "ckeditor_article_body_html"
        para "CKEditor 5 enhances this textarea; Rails still owns authorization, validation, sanitization, and persistence."
        textarea article.body_html,
                 id: "ckeditor_article_body_html",
                 name: "ckeditor_article[body_html]",
                 rows: 18
        react_component(
          "CkeditorEditor",
          props: { textareaId: "ckeditor_article_body_html" },
          class: "mt-3"
        )
        if article.errors[:body_html].any?
          ul class: "ckeditor-errors", role: "alert" do
            article.errors.full_messages_for(:body_html).each { |message| li message }
          end
        end
      end
    end
    form.actions

    panel "Demo" do
      para "Edit headings, emphasis, lists, links, quotes, and code with a locally bundled CKEditor 5 build."
      para "With JavaScript disabled—or if initialization fails—the same field remains a conventional HTML textarea."
    end
    panel "Ruby" do
      para "CkeditorArticle scopes records to the signed-in administrator and sanitizes every submission through a narrow allowlist."
      para "Scripts, embeds, images, inline styles, event handlers, and unsafe link protocols are not persisted."
    end
    panel "JavaScript" do
      para "The React island owns only CKEditor setup, form synchronization, and lifecycle teardown around the Rails textarea."
      para "The GPL package is bundled locally: no cloud service, API key, premium plugin, CDN, or telemetry endpoint is configured."
    end
    panel "Architecture" do
      para "Rails owns record scope, persistence, validation, sanitization, preview, optimistic locking, and media policy."
      para "Uploads remain outside this experiment; no image, media, CKBox, CKFinder, or upload adapter is enabled."
    end
  end
end
