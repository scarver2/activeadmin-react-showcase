# app/services/hierarchy/seed.rb
# frozen_string_literal: true

module Hierarchy
  class Seed
    BLUEPRINT = {
      "Showcase Company" => {
        "Engineering" => [ "Platform", "Product" ],
        "Operations" => [ "Customer Success", "Field Team" ],
        "Studio" => []
      }
    }.freeze

    def self.call(admin_user:)
      new(admin_user).call
    end

    def initialize(admin_user)
      @admin_user = admin_user
    end

    def call
      BLUEPRINT.each_with_index { |(title, children), index| seed_branch(title, children, nil, index) }
      admin_user.hierarchy_nodes
    end

    private

    attr_reader :admin_user

    def seed_branch(title, children, parent, position)
      node = admin_user.hierarchy_nodes.find_or_initialize_by(title:)
      node.update!(parent:, position:)
      children.each_with_index do |(child_title, grandchildren), index|
        seed_branch(child_title, Array(grandchildren).index_with { [] }, node, index)
      end
      node
    end
  end
end
