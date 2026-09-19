# app/models/hierarchy_node.rb
# frozen_string_literal: true

class HierarchyNode < ApplicationRecord
  MAXIMUM_DEPTH = 4

  belongs_to :admin_user

  has_ancestry ancestry_format: :materialized_path2, cache_depth: true, orphan_strategy: :restrict

  validates :ancestry_depth, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAXIMUM_DEPTH - 1, only_integer: true }
  validates :position, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :title, presence: true, length: { maximum: 80 }
  validate :parent_belongs_to_owner

  scope :ordered, -> { order(:position, :title, :id) }

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id ancestry ancestry_depth created_at id position title updated_at]
  end

  private

  def parent_belongs_to_owner
    errors.add(:parent, "must belong to the same administrator") if parent && parent.admin_user_id != admin_user_id
  end
end
