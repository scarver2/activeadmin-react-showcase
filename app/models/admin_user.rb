# app/models/admin_user.rb
# frozen_string_literal: true

class AdminUser < ApplicationRecord
  has_many :agent_runs, dependent: :destroy
  has_many :operations, dependent: :destroy
  has_many :schedule_events, dependent: :destroy
  has_many :hierarchy_nodes, dependent: :destroy
  has_many :terminal_executions, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id updated_at]
  end
end
