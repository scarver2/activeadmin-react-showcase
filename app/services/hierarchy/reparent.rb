# app/services/hierarchy/reparent.rb
# frozen_string_literal: true

module Hierarchy
  class Reparent
    class StaleWrite < StandardError; end

    def self.call(admin_user:, node:, parent_id:, position:, expected_lock_version:)
      new(admin_user:, node:, parent_id:, position:, expected_lock_version:).call
    end

    def initialize(admin_user:, node:, parent_id:, position:, expected_lock_version:)
      @admin_user = admin_user
      @expected_lock_version = expected_lock_version
      @node = node
      @parent_id = parent_id.presence
      @position = position
    end

    def call
      node.with_lock do
        raise StaleWrite, "This hierarchy changed after it loaded" unless node.lock_version == parsed_lock_version

        node.update!(parent: parent, position: Integer(position.to_s, 10))
      end
      node
    rescue ArgumentError
      raise ActiveRecord::RecordInvalid, node.tap { |record| record.errors.add(:position, "must be an integer") }
    end

    private

    attr_reader :admin_user, :expected_lock_version, :node, :parent_id, :position

    def parent
      parent_id && admin_user.hierarchy_nodes.find(parent_id)
    end

    def parsed_lock_version
      Integer(expected_lock_version.to_s, 10, exception: false)
    end
  end
end
