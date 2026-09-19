# app/services/inline_editing/serializer.rb
# frozen_string_literal: true

module InlineEditing
  class Serializer
    def initialize(account)
      @account = account
    end

    def as_json(*)
      { id: account.id, lockVersion: account.lock_version, region: account.region, status: account.status }
    end

    private

    attr_reader :account
  end
end
