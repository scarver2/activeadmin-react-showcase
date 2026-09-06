# app/services/operations/claim.rb
# frozen_string_literal: true

module Operations
  class Claim
    LEASE = 30.seconds

    class Busy < StandardError; end

    def self.call(operation:, claim_key:, now: Time.current)
      operation.with_lock do
        operation.reload
        return false if operation.terminal?
        if operation.claim_key.present? && operation.claim_key != claim_key && operation.claim_expires_at && operation.claim_expires_at > now
          raise Busy, "operation is already claimed"
        end

        operation.update!(claim_key:, claim_expires_at: now + LEASE)
      end
      true
    end
  end
end
