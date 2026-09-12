# app/admin/spacecraft_viewer.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Spacecraft Viewer" do
  menu label: "Spacecraft Viewer", parent: "System", priority: 8
  content title: "Rails-authoritative Three.js Spacecraft Viewer" do
    model = Spacecraft::Seed.call(admin_user: current_admin_user)
    panel("Demo") { para "Orbit the local Odyssey model, inspect components, choose camera presets, explode the assembly, and persist an allowlisted finish." }
    react_component("SpacecraftViewer", props: { model: Spacecraft::Serializer.new(model).as_json }, fallback: lambda {
      safe_join([ content_tag(:p, "The engineering metadata remains useful without WebGL or JavaScript."), content_tag(:h2, model.name), content_tag(:p, "Finish: #{model.finish}"), content_tag(:ul, safe_join(Spacecraft::Catalog::COMPONENTS.map { |component| content_tag(:li, "#{component[:name]} — #{component[:partNumber]} — #{component[:material]} — #{component[:status]}") })), link_to("Edit model configuration", edit_admin_spacecraft_model_path(model)) ])
    }, class: "mt-6")
    panel("Ruby", id: "ruby-guidance") { para "Rails owns model identity, component metadata, local asset URL, authorization, allowlisted finishes, and persisted selection." }
    panel("JavaScript", id: "javascript-guidance") { para "A lazy Three.js island owns rendering, raycasting, camera state, controls, and bounded exploded-view presentation." }
    panel("Architecture", id: "architecture-guidance") { para "The local low-polygon glTF and strict lifecycle budget demonstrate integration, not a CAD or scene-editor API." }
  end
end
