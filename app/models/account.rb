# app/models/account.rb
# frozen_string_literal: true

class Account < ApplicationRecord
  PLANS = %w[Enterprise Growth Starter].freeze
  REGIONS = %w[Central East West].freeze
  STATUSES = %w[active trial].freeze

  has_many :daily_metrics, dependent: :destroy

  validates :name, :plan, :region, :status, presence: true
  validates :name, uniqueness: true
  validates :plan, inclusion: { in: PLANS }
  validates :region, inclusion: { in: REGIONS }
  validates :status, inclusion: { in: STATUSES }

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name plan region status updated_at]
  end
end
