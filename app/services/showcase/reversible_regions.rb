# app/services/showcase/reversible_regions.rb
# frozen_string_literal: true

module Showcase
  class ReversibleRegions
    class Rejected < StandardError; end

    WINDOW = 30.seconds

    def self.change(admin_user:, account:, value:, request_key:, expected_version:, now: nil)
      raise Rejected, "Administrator required" unless admin_user&.persisted?
      raise Rejected, "Invalid request key" unless request_key.to_s.match?(/\A[0-9a-f-]{36}\z/)
      raise Rejected, "Unsupported region" unless Account::REGIONS.include?(value)

      Operations::DatabaseRetry.call do
        admin_user.with_lock do
          existing = ReversibleChange.find_by(admin_user:, request_key:)
          if existing
            raise Rejected, "Request key reused with different input" unless existing.account_id == account.id && existing.after_value == value

            return existing
          end
          account.with_lock do
            raise Rejected, "Region is not editable" unless InlineEditing::Policy.new(admin_user:, account:).permitted?("region")
            raise Rejected, "Account changed; reload before trying again" unless account.lock_version == Integer(expected_version)
            raise Rejected, "Choose a different region" if account.region == value

            previous = account.region
            account.update!(region: value)
            receipt = ReversibleChange.create!(admin_user:, account:, request_key:, before_value: previous,
              after_value: value, applied_lock_version: account.lock_version, expires_at: (now || Time.current) + WINDOW)
            receipt.events.create!(admin_user:, kind: "change", from_value: previous, to_value: value)
            receipt
          end
        end
      end
    rescue ArgumentError, TypeError
      raise Rejected, "Invalid version"
    rescue ActiveRecord::StaleObjectError
      raise Rejected, "Account changed; reload before trying again"
    end

    def self.undo(admin_user:, id:, now: nil)
      raise Rejected, "Administrator required" unless admin_user&.persisted?

      Operations::DatabaseRetry.call do
        receipt = ReversibleChange.where(admin_user:).find(id)
        receipt.with_lock do
          return receipt if receipt.undone_at

          receipt.account.with_lock do
            command_time = now || Time.current
            state = receipt.undo_state(now: command_time)
            raise Rejected, "Undo unavailable: #{state}" unless state == "available"

            receipt.account.update!(region: receipt.before_value)
            receipt.events.create!(admin_user:, kind: "undo", from_value: receipt.after_value, to_value: receipt.before_value)
            receipt.update!(undone_at: command_time)
          end
        end
        receipt
      end
    rescue ActiveRecord::StaleObjectError
      raise Rejected, "Account changed; undo was not applied"
    end
  end
end
