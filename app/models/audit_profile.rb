# app/models/audit_profile.rb
# frozen_string_literal: true

class AuditProfile < ApplicationRecord
  belongs_to :admin_user
  has_paper_trail

  validates :name, :plan, presence: true

  def self.ransackable_attributes(_auth_object = nil) = %w[created_at id name plan updated_at]
end
