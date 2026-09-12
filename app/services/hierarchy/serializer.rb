# app/services/hierarchy/serializer.rb
# frozen_string_literal: true

module Hierarchy
  class Serializer
    def initialize(node)
      @node = node
    end

    def as_json(*)
      {
        breadcrumbs: node.ancestors.map { |ancestor| { id: ancestor.id.to_s, title: ancestor.title } },
        childCount: node.children.size,
        childrenUrl: Rails.application.routes.url_helpers.admin_hierarchy_nodes_path(parent_id: node.id),
        id: node.id.to_s,
        lockVersion: node.lock_version,
        moveUrl: Rails.application.routes.url_helpers.admin_hierarchy_node_path(node),
        title: node.title
      }
    end

    private

    attr_reader :node
  end
end
