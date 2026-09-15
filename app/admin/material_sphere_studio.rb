# app/admin/material_sphere_studio.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Material Sphere Studio" do
  menu label: "Material Sphere Studio", parent: "System", priority: 8

  content title: "Rails-authoritative Three.js Material Sphere Studio" do
    model = MaterialStudio::Seed.call(admin_user: current_admin_user)
    panel("Demo") { para "Orbit a procedural glossy red sphere, compare allowlisted physical-material recipes, and inspect high-specularity studio lighting without remote assets." }
    react_component("MaterialSphereStudio", props: { model: MaterialStudio::Serializer.new(model).as_json }, fallback: lambda {
      finish = MaterialStudio::Catalog::FINISHES.find { |candidate| candidate.fetch(:id) == model.finish }
      safe_join([ content_tag(:p, "The Rails-owned material recipe remains useful without WebGL or JavaScript."), content_tag(:h2, model.name), content_tag(:p, "Finish: #{finish.fetch(:label)}"), content_tag(:dl, safe_join(finish.except(:id, :label).flat_map { |name, value| [ content_tag(:dt, name.to_s.humanize), content_tag(:dd, value) ] })), link_to("Edit material configuration", edit_admin_material_sphere_path(model)) ])
    }, class: "mt-6")
    panel("Ruby", id: "ruby-guidance") { para "Rails owns model identity, authorization, optimistic locking, and the allowlisted physical-material recipes." }
    panel("JavaScript", id: "javascript-guidance") { para "A lazy Three.js island owns procedural geometry, physically based rendering, studio lighting, camera state, and orbit controls." }
    panel("Architecture", id: "architecture-guidance") { para "The deterministic local scene demonstrates lifecycle-safe WebGL integration without a downloaded model, remote HDRI, licensing burden, or a generic scene-editor abstraction." }
  end
end
