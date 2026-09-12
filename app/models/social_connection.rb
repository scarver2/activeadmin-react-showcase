# app/models/social_connection.rb
# frozen_string_literal: true

class SocialConnection < ApplicationRecord
  belongs_to :person_a, class_name: "SocialPerson"
  belongs_to :person_b, class_name: "SocialPerson"
  validate :same_owner
  validates :person_a_id, comparison: { less_than: :person_b_id }, uniqueness: { scope: :person_b_id }
  private
  def same_owner
    errors.add(:base, "People must share an owner") if person_a && person_b && person_a.admin_user_id != person_b.admin_user_id
  end
end
