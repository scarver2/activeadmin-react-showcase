# app/services/hierarchy/query.rb
# frozen_string_literal: true

module Hierarchy
  class Query
    MAXIMUM_CHILDREN = 50

    def initialize(admin_user:, parent_id: nil)
      @admin_user = admin_user
      @parent_id = parent_id.presence
    end

    def as_json
      { nodes: nodes.map { |node| Serializer.new(node).as_json } }
    end

    private

    attr_reader :admin_user, :parent_id

    def nodes
      relation = parent_id ? admin_user.hierarchy_nodes.find(parent_id).children : admin_user.hierarchy_nodes.roots
      relation.limit(MAXIMUM_CHILDREN)
    end
  end
end
