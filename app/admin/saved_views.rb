# app/admin/saved_views.rb
# frozen_string_literal: true

ActiveAdmin.register SavedView do
  menu label: "Saved Workspaces", parent: "Data & Reporting", priority: 3
  permit_params :name, :favorite, :lock_version,
                definition: [ :schema, :query, :plan, :status, :sort, :direction, :per_page, :group, :density, columns: [] ]
  config.batch_actions = false
  filter :name
  filter :favorite

  collection_action :default_workspace, method: :get do
    selected = current_admin_user.saved_views.find_by(default_view: true)
    redirect_to selected ? admin_saved_view_path(selected) : admin_saved_views_path
  end

  controller do
    def scoped_collection
      current_admin_user.saved_views
    end

    def build_new_resource
      super.tap do |view|
        view.admin_user = current_admin_user
        view.definition = SavedView::DEFAULT_DEFINITION.deep_dup if view.definition.blank?
      end
    end

    def permitted_params
      params.permit(saved_view: [ :name, :favorite, :lock_version,
                                 definition: [ :schema, :query, :plan, :status, :sort, :direction, :per_page, :group, :density, columns: [] ] ]).tap do |allowed|
        values = allowed.dig(:saved_view, :definition)
        if values
          values[:schema] = 1
          values[:columns] = Array(values[:columns]).reject(&:blank?)
        end
      end
    end

    rescue_from ActiveRecord::StaleObjectError do
      redirect_to edit_resource_path, alert: "This view changed in another tab. Reload its current definition before saving."
    end

    rescue_from ActiveRecord::RecordNotFound do
      head :not_found
    end
  end

  member_action :duplicate, method: :post do
    copy = current_admin_user.saved_views.new(name: "#{resource.name.first(60)} copy #{SecureRandom.hex(4)}", definition: resource.definition.deep_dup)
    copy.save!
    redirect_to edit_admin_saved_view_path(copy), notice: "Personal copy created."
  end

  member_action :make_default, method: :post do
    resource.make_default!
    redirect_to resource_path, notice: "Default workspace selected."
  end

  index do
    column(:name) { |view| link_to view.name, admin_saved_view_path(view) }
    column :favorite
    column :default_view
    actions
  end

  show do
    panel "Personal workspace" do
      para "Only you can read or change this definition. Account access is checked by the existing authenticated account surface."
      div class: "saved-workspace-controls" do
        text_node button_to("Duplicate view", duplicate_admin_saved_view_path(resource), method: :post)
        text_node button_to("Make default", make_default_admin_saved_view_path(resource), method: :post)
      end
      begin
        definition = resource.normalized_definition
        data = resource.account_data(page: params[:page] || 1)
        render partial: "admin/saved_views/results", locals: { definition:, data:, view: resource }
      rescue ArgumentError => error
        para error.message, role: "alert"
        para link_to("Repair view definition", edit_admin_saved_view_path(resource))
      end
    end
    panel "Implementation" do
      para "Rails validates and persists the versioned definition; the existing account query owns filtering and canonical resource URLs. React enhances only the editor fields."
      pre(class: "saved-workspace-code") { code("SavedView#account_data → Showcase::AccountExplorer → authorized synthetic account rows") }
      pre(class: "saved-workspace-code") { code('registerComponent("SavedViewEditor", SavedViewEditor)') }
      para link_to("Read the saved-workspace contract", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/saved-workspaces.md")
    end
  end

  form do |form|
    form.semantic_errors(*form.object.errors.attribute_names)
    form.inputs do
      form.input :name
      form.input :favorite
      form.input :lock_version, as: :hidden
    end
    definition = begin
      form.object.normalized_definition
    rescue ArgumentError
      SavedView::DEFAULT_DEFINITION.deep_dup
    end
    react_component("SavedViewEditor", props: { definition:, columns: SavedView::COLUMNS, plans: Account::PLANS, statuses: Account::STATUSES },
                    fallback: -> { helpers.render partial: "admin/saved_views/fields", locals: { definition: } })
    form.actions
  end
end
