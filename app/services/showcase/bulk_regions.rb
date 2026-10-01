# app/services/showcase/bulk_regions.rb
# frozen_string_literal: true

module Showcase
  class BulkRegions
    class Rejected < StandardError; end

    LIMIT = 25

    def self.preview(admin_user:, ids:, region:)
      raise Rejected, "Administrator required" unless admin_user&.persisted?
      raise Rejected, "Unsupported region" unless Account::REGIONS.include?(region)
      raise Rejected, "Select between 1 and #{LIMIT} records" unless ids.is_a?(Array) && ids.size.between?(1, LIMIT)
      raise Rejected, "Invalid record identifiers" unless ids.all? { |id| id.to_s.match?(/\A\d+\z/) }

      selection = ids.map(&:to_i).uniq.map do |id|
        account = Account.find_by(id:)
        reason = if account.nil?
          "missing"
        elsif !InlineEditing::Policy.new(admin_user:, account:).permitted?("region")
          "unauthorized"
        elsif account.region == region
          "unchanged"
        else
          "eligible"
        end
        { id:, name: account&.name || "Missing account #{id}", version: account&.lock_version, reason: }
      end
      BulkRegionBatch.create!(admin_user:, region:, selection:)
    end

    def self.confirm(admin_user:, id:)
      batch = BulkRegionBatch.where(admin_user:).find(id)
      Operations::DatabaseRetry.call do
        batch.with_lock do
          batch.update!(state: "queued") if batch.state == "preview"
        end
      end
      BulkRegionJob.perform_later(batch.id) unless batch.state == "completed"
      batch
    end

    def self.perform(id)
      batch = BulkRegionBatch.find(id)
      batch.selection.each do |item|
        Operations::DatabaseRetry.call do
          batch.with_lock do
            key = item.fetch("id").to_s
            next if batch.results.key?(key) || batch.state == "preview"

            result = apply(batch, item)
            results = batch.results.merge(key => result)
            batch.update!(results:, state: results.size == batch.selection.size ? "completed" : "running")
          end
        end
      end
      batch.reload
    end

    def self.apply(batch, item)
      return item.fetch("reason") unless item.fetch("reason") == "eligible"

      account = Account.find_by(id: item.fetch("id"))
      return "missing" unless account

      account.with_lock do
        return "unauthorized" unless InlineEditing::Policy.new(admin_user: batch.admin_user, account:).permitted?("region")
        return "conflict" unless account.lock_version == item.fetch("version")

        account.update!(region: batch.region)
        "updated"
      end
    rescue ActiveRecord::RecordInvalid
      "invalid"
    rescue ActiveRecord::StaleObjectError
      "conflict"
    end
    private_class_method :apply
  end
end
