# app/admin/image_annotation_editor.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Image Annotation Editor" do
  menu label: "Image Annotation", parent: "Content", priority: 3

  content title: "Rails-authoritative Image Annotation" do
    routes = Rails.application.routes.url_helpers
    assets = ShowcaseAsset.with_attached_file.select { |asset| asset.file.image? }
    serialized = assets.map do |asset|
      annotation = current_admin_user.image_annotations.find_or_initialize_by(showcase_asset: asset)
      { id: asset.id, title: asset.title, url: rails_blob_path(asset.file, disposition: "inline"), saveUrl: routes.admin_image_annotation_path(asset), annotation: annotation.as_json(only: %i[focal_x focal_y label region_height region_width region_x region_y]) }
    end
    panel("Demo") { para "Choose a synthetic image, place a normalized focal point with pointer or keyboard, and persist bounded metadata through Rails." }
    react_component("ImageAnnotationEditor", props: { assets: serialized }, fallback: -> {
      safe_join(assets.map do |asset|
        form_with url: routes.admin_image_annotation_path(asset), method: :patch do |form|
          safe_join([ content_tag(:h3, asset.title), image_tag(rails_blob_path(asset.file), alt: ""), form.label(:focal_x), form.number_field(:focal_x, min: 0, max: 1, step: 0.01), form.label(:focal_y), form.number_field(:focal_y, min: 0, max: 1, step: 0.01), form.submit("Save annotation") ])
        end
      end)
    })
    panel("Ruby") { para "ImageEditor::Save allowlists normalized metadata; model validation enforces coordinate and image bounds." }
    panel("JavaScript") { para "A responsive canvas owns pointer and keyboard interaction and redraws from canonical normalized values." }
    panel("Architecture") { para link_to("Read the image annotation guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/image-annotation.md") }
  end
end
