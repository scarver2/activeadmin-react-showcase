# app/services/operations/claim.rb
# frozen_string_literal: true

module Operations
  class Claim
    LEASE = 30.seconds
    Lease = Data.define(:token, :generation)

    class Busy < StandardError; end
    class Stale < StandardError; end
    class Expired < Stale; end

    def self.call(operation:, token: SecureRandom.uuid, now: Time.current)
      Operations::DatabaseRetry.call do
        operation.with_lock do
          operation.reload
          return if operation.terminal?
          if operation.claim_key.present? && operation.claim_expires_at && operation.claim_expires_at > now
            raise Busy, "operation is already claimed"
          end

          generation = operation.claim_generation + 1
          operation.update!(claim_generation: generation, claim_key: token, claim_expires_at: now + LEASE)
          Lease.new(token:, generation:)
        end
      end
    end

    def self.verify_locked!(operation:, lease:, now: Time.current)
      operation.reload
      unless operation.claim_key == lease.token && operation.claim_generation == lease.generation
        raise Stale, "operation claim was superseded"
      end
      raise Expired, "operation claim expired" unless operation.claim_expires_at && operation.claim_expires_at > now
    end

    def self.renew!(operation:, lease:, now: Time.current)
      Operations::DatabaseRetry.call do
        operation.with_lock do
          verify_locked!(operation:, lease:, now:)
          operation.update!(claim_expires_at: now + LEASE)
        end
      end
    end

    def self.renewal(now: Time.current)
      { claim_expires_at: now + LEASE }
    end
  end
end
