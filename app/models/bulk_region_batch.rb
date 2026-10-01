# app/models/bulk_region_batch.rb
# frozen_string_literal: true

class BulkRegionBatch < ApplicationRecord
  belongs_to :admin_user
  validates :region, inclusion: { in: Account::REGIONS }
  validates :state, inclusion: { in: %w[preview queued running completed] }

  def progress
    selection.empty? ? 100 : (results.size * 100 / selection.size)
  end
end
