# app/services/inline_editing/update.rb
# frozen_string_literal: true

module InlineEditing
  class Update
    class Forbidden < StandardError; end
    class StaleWrite < StandardError; end

    VALUES = { "region" => Account::REGIONS, "status" => Account::STATUSES }.freeze

    def self.call(admin_user:, account:, field:, value:, expected_lock_version:)
      normalized_field = field.to_s
      raise Forbidden, "Field is not editable for this record" unless Policy.new(admin_user:, account:).permitted?(normalized_field)
      raise ActiveRecord::RecordInvalid, account unless VALUES.fetch(normalized_field).include?(value.to_s)

      account.lock_version = Integer(expected_lock_version)
      account.update!(normalized_field => value)
      account
    rescue ActiveRecord::StaleObjectError
      account.reload
      raise StaleWrite, "This account changed elsewhere; the canonical value was restored"
    rescue ArgumentError, KeyError
      raise ActiveRecord::RecordInvalid, account
    end
  end
end
