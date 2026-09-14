# app/admin/content_builder.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Content Builder" do
  menu label: "Content Builder", parent: "Data & Workflows", priority: 6
  content title: "Rails-authoritative Content Builder" do
    document = ContentBuilder::Seed.call(admin_user: current_admin_user)
    panel("Demo") { para "Add, edit, remove, and reorder a deliberately small allowlist of content blocks, then persist the normalized result." }
    react_component("ContentBuilder", props: { document: ContentBuilder::Serializer.new(document).as_json }, fallback: lambda {
      safe_join([ content_tag(:p, "The normalized document remains readable and editable without JavaScript."),
                 content_tag(:h2, document.title),
                 content_tag(:ol, safe_join(document.content_blocks.map { |block| content_tag(:li, "#{block.block_type}: #{block.body}") })),
                 link_to("Edit document record", edit_admin_content_document_path(document)) ])
    }, class: "mt-6")
    panel("Ruby", id: "ruby-guidance") { para "ContentBuilder::Save replaces normalized blocks transactionally after validating type, attributes, order, count, ownership, and lock version." }
    panel("JavaScript", id: "javascript-guidance") { para "dnd-kit and keyboard controls manage transient composition; React rolls back when Rails rejects the proposal." }
    panel("Architecture", id: "architecture-guidance") { para "This is a bounded application schema, not an unconstrained browser document or generic page builder." }
  end
end
