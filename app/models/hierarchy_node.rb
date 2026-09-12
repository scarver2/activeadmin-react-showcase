# app/models/hierarchy_node.rb
# frozen_string_literal: true

class HierarchyNode < ApplicationRecord
  MAXIMUM_DEPTH = 4

  belongs_to :admin_user
  belongs_to :parent, class_name: "HierarchyNode", optional: true
  has_many :children, -> { order(:position, :title, :id) }, class_name: "HierarchyNode", dependent: :restrict_with_error, foreign_key: :parent_id, inverse_of: :parent

  validates :position, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :title, presence: true, length: { maximum: 80 }
  validate :parent_belongs_to_owner
  validate :parent_is_not_descendant
  validate :depth_is_bounded

  scope :roots, -> { where(parent_id: nil).order(:position, :title, :id) }

  def ancestors
    nodes = []
    cursor = parent
    while cursor
      nodes.unshift(cursor)
      cursor = cursor.parent
    end
    nodes
  end

  def depth
    ancestors.length
  end

  def descendant_of?(candidate)
    (candidate.id && parent_id == candidate.id) || parent&.descendant_of?(candidate) || false
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id created_at id parent_id position title updated_at]
  end

  private

  def depth_is_bounded
    errors.add(:parent, "would exceed four levels") if parent && parent.depth + 1 >= MAXIMUM_DEPTH
  end

  def parent_belongs_to_owner
    errors.add(:parent, "must belong to the same administrator") if parent && parent.admin_user_id != admin_user_id
  end

  def parent_is_not_descendant
    errors.add(:parent, "cannot create a cycle") if parent && parent.descendant_of?(self)
  end
end
