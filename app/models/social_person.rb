# app/models/social_person.rb
# frozen_string_literal: true

class SocialPerson < ApplicationRecord
  belongs_to :admin_user
  validates :headline, :name, presence: true
  validates :name, uniqueness: { scope: :admin_user_id }
  def neighbors
    ids = SocialConnection.where(person_a: self).pluck(:person_b_id) + SocialConnection.where(person_b: self).pluck(:person_a_id)
    self.class.where(id: ids)
  end
  def self.ransackable_attributes(_auth_object = nil) = %w[admin_user_id created_at headline id name updated_at]
end
