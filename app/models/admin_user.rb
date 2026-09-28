# app/models/admin_user.rb
# frozen_string_literal: true

class AdminUser < ApplicationRecord
  THEME_PREFERENCES = {
    "v3" => "Classic Neutral",
    "v3_texas" => "Limestone & Ink",
    "v3_slate" => "Slate & Copper"
  }.freeze

  has_many :image_annotations, dependent: :destroy
  has_many :material_spheres, dependent: :destroy
  has_many :audit_profiles, dependent: :destroy
  has_many :onboarding_drafts, dependent: :destroy
  has_many :agent_runs, dependent: :destroy
  has_many :activity_notifications, dependent: :destroy
  has_many :content_documents, dependent: :destroy
  has_many :csv_imports, dependent: :destroy
  has_many :operations, dependent: :destroy
  has_many :schedule_events, dependent: :destroy
  has_many :social_people, dependent: :destroy
  has_many :hierarchy_nodes, dependent: :destroy
  has_many :terminal_executions, dependent: :destroy
  has_many :tiny_mce_articles, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  validates :theme_preference, inclusion: { in: THEME_PREFERENCES.keys }

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id updated_at]
  end
end
