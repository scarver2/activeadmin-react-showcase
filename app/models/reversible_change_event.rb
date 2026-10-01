# app/models/reversible_change_event.rb
# frozen_string_literal: true

class ReversibleChangeEvent < ApplicationRecord
  belongs_to :reversible_change
  belongs_to :admin_user
  validates :kind, inclusion: { in: %w[change undo] }, uniqueness: { scope: :reversible_change_id }
  validates :from_value, :to_value, inclusion: { in: Account::REGIONS }

  def readonly?
    persisted?
  end
end
