# app/admin/social_network.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Social Network" do
  menu label: "Social Network", parent: "Data & Workflows", priority: 7
  content title: "Rails-authoritative Social Relationship Graph" do
    people = SocialGraph::Seed.call(admin_user: current_admin_user)
    root = people.first
    graph = SocialGraph::Explorer.new(admin_user: current_admin_user, root_id: root.id).as_json
    panel("Demo") { para "Explore first through third-degree synthetic connections, mutual contacts, and bounded shortest paths." }
    react_component("SocialGraphExplorer", props: { endpoint: Rails.application.routes.url_helpers.admin_social_graph_path, graph:, people: people.map { |person| { id: person.id.to_s, name: person.name } }, rootId: root.id.to_s }, fallback: lambda {
      safe_join([ content_tag(:p, "Relationships and paths remain readable without JavaScript."), content_tag(:ul, safe_join(root.neighbors.order(:name).map { |person| content_tag(:li, link_to("#{person.name} — #{person.headline}", admin_social_person_path(person))) })) ])
    }, class: "mt-6")
    panel("Ruby", id: "ruby-guidance") { para "SocialGraph::Explorer owns bounded projections, mutuals, shortest paths, authorization, and generated URLs." }
    panel("JavaScript", id: "javascript-guidance") { para "Cytoscape owns transient layout, pan/zoom, selection, and path highlighting." }
    panel("Architecture", id: "architecture-guidance") { para "Hard caps keep this a social-network demonstration rather than a generic graph database." }
  end
end
