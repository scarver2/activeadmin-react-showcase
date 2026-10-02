# app/services/showcase/contextual_relationships.rb
# frozen_string_literal: true

module Showcase
  # Shared synthetic fixtures have an explicit visibility policy. Live adapters
  # must apply their owning domain policies before supplying either endpoint.
  class ContextualRelationships
    PATH = "/admin/contextual_relationships"
    MAX_NODES = 24
    MAX_EDGES = 40
    NODES = [
      { id: "customer", kind: "Customer", name: "Juniper Dispatch", detail: "Fictional customer arranging reusable packing crates." },
      { id: "contact", kind: "Contact", name: "Avery Vale", detail: "Fictional dispatch contact." },
      { id: "order", kind: "Order", name: "Crate order JD-104", detail: "Twelve reusable crates; synthetic order in review." },
      { id: "project", kind: "Project", name: "Autumn dispatch", detail: "Synthetic packing and dispatch project." },
      { id: "work", kind: "Work Item", name: "Review packing checklist", detail: "Human review of the fictional packing checklist." },
      { id: "conversation", kind: "Conversation", name: "Packing discussion", detail: "Synthetic discussion of crate labels." },
      { id: "file", kind: "File", name: "packing-checklist.txt", detail: "Synthetic checklist metadata; no uploaded content." },
      { id: "deleted", kind: "File", name: "Deleted draft", detail: "Must not be projected.", state: "deleted" },
      { id: "restricted", kind: "Order", name: "Restricted order", detail: "Must not be projected.", state: "restricted" }
    ].freeze
    EDGES = [
      [ "customer", "contact", "has contact" ], [ "customer", "order", "placed" ],
      [ "order", "project", "delivered by" ], [ "project", "work", "includes" ],
      [ "work", "conversation", "discussed in" ], [ "conversation", "file", "references" ],
      [ "contact", "conversation", "participates in" ], [ "work", "order", "reviews" ],
      [ "customer", "restricted", "placed" ], [ "conversation", "deleted", "references" ],
      [ "project", "missing", "references" ]
    ].freeze

    def initialize(admin_user:, nodes: NODES, edges: EDGES)
      raise ActiveRecord::RecordNotFound unless admin_user&.persisted?

      @nodes = nodes.select { |node| node.fetch(:state, "available") == "available" }.index_by { |node| node.fetch(:id) }
      @edges = edges.select { |source, target, _| @nodes.key?(source) && @nodes.key?(target) }
    end

    def find(id)
      node = @nodes.fetch(id.to_s) { raise ActiveRecord::RecordNotFound }
      node.merge(url: "#{PATH}?source=#{ERB::Util.url_encode(node.fetch(:id))}", exploreUrl: "#{PATH}?root=#{ERB::Util.url_encode(node.fetch(:id))}")
    end

    def graph(root: "customer", depth: 1)
      depth = Integer(depth.to_s, exception: false)
      raise ArgumentError, "Choose a relationship depth from 1 to 3." unless depth&.between?(1, 3)

      root = find(root).fetch(:id)
      visited = [ root ]
      frontier = [ root ]
      depth.times do
        neighbors = @edges.flat_map { |source, target, _| frontier.include?(source) || frontier.include?(target) ? [ source, target ] : [] }
        frontier = neighbors.uniq.sort - visited
        visited = (visited + frontier).take(MAX_NODES)
        frontier &= visited
      end
      edges = @edges.select { |source, target, _| visited.include?(source) && visited.include?(target) }
      {
        rootId: root, depth:, nodes: visited.map { |id| find(id) },
        edges: edges.take(MAX_EDGES).each_with_index.map { |(source, target, label), index| { id: "edge-#{index}", source:, target:, label: } },
        bounded: visited.size == MAX_NODES || edges.size > MAX_EDGES
      }
    end
  end
end
