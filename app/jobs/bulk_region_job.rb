# app/jobs/bulk_region_job.rb
# frozen_string_literal: true

class BulkRegionJob < ApplicationJob
  queue_as :default

  def perform(id)
    Showcase::BulkRegions.perform(id)
  end
end
