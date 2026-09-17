# app/admin/image_annotation_editor.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Image Annotation Editor" do
  menu label: "Image Editor & Annotation Studio", parent: "Content", priority: 3

  content title: "Image Editor & Annotation Studio" do
    routes = Rails.application.routes.url_helpers
    assets = ShowcaseAsset.with_attached_file.select { |asset| asset.file.image? }
    serialized = assets.map do |asset|
      annotation = current_admin_user.image_annotations.find_or_initialize_by(showcase_asset: asset)
      serialized = annotation.as_json(only: %i[focal_x focal_y label region_height region_width region_x region_y])
      serialized["edit_specification"] = annotation.canonical_edit_specification
      { id: asset.id, title: asset.title, url: rails_blob_path(asset.file, disposition: "inline"), saveUrl: routes.admin_image_annotation_path(asset), annotation: serialized }
    end
    panel("Demo") { para "Nondestructively crop, rotate, flip, and adjust a synthetic image; compare the live processed preview; retain focal-point and annotation metadata; then persist the bounded recipe through Rails." }
    react_component("ImageAnnotationEditor", props: { assets: serialized }, fallback: -> {
      safe_join(assets.map do |asset|
        annotation = current_admin_user.image_annotations.find_or_initialize_by(showcase_asset: asset)
        edit = annotation.canonical_edit_specification
        form_with url: routes.admin_image_annotation_path(asset), method: :patch do |form|
          safe_join([
            content_tag(:h3, asset.title), image_tag(rails_blob_path(asset.file), alt: asset.title),
            form.label(:focal_x), form.number_field(:focal_x, min: 0, max: 1, step: 0.01, value: annotation.focal_x),
            form.label(:focal_y), form.number_field(:focal_y, min: 0, max: 1, step: 0.01, value: annotation.focal_y),
            helpers.label_tag("edit_specification_crop_x", "Crop x"), helpers.number_field_tag("edit_specification[crop_x]", edit["crop_x"], id: "edit_specification_crop_x", min: 0, max: 1, step: 0.01),
            helpers.label_tag("edit_specification_crop_y", "Crop y"), helpers.number_field_tag("edit_specification[crop_y]", edit["crop_y"], id: "edit_specification_crop_y", min: 0, max: 1, step: 0.01),
            helpers.label_tag("edit_specification_crop_width", "Crop width"), helpers.number_field_tag("edit_specification[crop_width]", edit["crop_width"], id: "edit_specification_crop_width", min: 0.01, max: 1, step: 0.01),
            helpers.label_tag("edit_specification_crop_height", "Crop height"), helpers.number_field_tag("edit_specification[crop_height]", edit["crop_height"], id: "edit_specification_crop_height", min: 0.01, max: 1, step: 0.01),
            helpers.label_tag("edit_specification_brightness", "Brightness"), helpers.number_field_tag("edit_specification[brightness]", edit["brightness"], id: "edit_specification_brightness", min: 0.5, max: 1.5, step: 0.05),
            helpers.label_tag("edit_specification_contrast", "Contrast"), helpers.number_field_tag("edit_specification[contrast]", edit["contrast"], id: "edit_specification_contrast", min: 0.5, max: 1.5, step: 0.05),
            helpers.label_tag("edit_specification_saturation", "Saturation"), helpers.number_field_tag("edit_specification[saturation]", edit["saturation"], id: "edit_specification_saturation", min: 0, max: 2, step: 0.05),
            helpers.label_tag("edit_specification_rotation", "Rotation"), helpers.select_tag("edit_specification[rotation]", helpers.options_for_select([ 0, 90, 180, 270 ], edit["rotation"]), id: "edit_specification_rotation"),
            helpers.hidden_field_tag("edit_specification[flip_x]", "0"), helpers.check_box_tag("edit_specification[flip_x]", "1", edit["flip_x"], id: "edit_specification_flip_x"), helpers.label_tag("edit_specification_flip_x", "Flip horizontal"),
            helpers.hidden_field_tag("edit_specification[flip_y]", "0"), helpers.check_box_tag("edit_specification[flip_y]", "1", edit["flip_y"], id: "edit_specification_flip_y"), helpers.label_tag("edit_specification_flip_y", "Flip vertical"),
            helpers.hidden_field_tag("edit_specification[grayscale]", "0"), helpers.check_box_tag("edit_specification[grayscale]", "1", edit["grayscale"], id: "edit_specification_grayscale"), helpers.label_tag("edit_specification_grayscale", "Grayscale"),
            helpers.hidden_field_tag("edit_specification[sepia]", "0"), helpers.check_box_tag("edit_specification[sepia]", "1", edit["sepia"], id: "edit_specification_sepia"), helpers.label_tag("edit_specification_sepia", "Sepia"),
            form.submit("Save image recipe")
          ])
        end
      end)
    })
    panel("Ruby") { para "ImageEditor::Save allowlists a normalized edit specification; model validation enforces crop, filter, rotation, coordinate, and image bounds." }
    panel("JavaScript") { para "Two responsive canvases own crop/focal interaction and nondestructive source-to-preview rendering from canonical values." }
    panel("Architecture") { para link_to("Read the image editing and annotation guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/image-annotation.md") }
  end
end
