# app/models/contact.rb
# frozen_string_literal: true

class Contact < ApplicationRecord
  RELATIONSHIP_ROLES = [ "Executive sponsor", "Operations lead", "Technical lead" ].freeze

  belongs_to :account

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :job_title, :last_name, with: ->(value) { value.strip }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :first_name, :job_title, :last_name, length: { in: 1..80 }
  validates :relationship_role, inclusion: { in: RELATIONSHIP_ROLES }

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[account]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[account_id created_at email first_name id job_title last_name relationship_role updated_at]
  end
end
