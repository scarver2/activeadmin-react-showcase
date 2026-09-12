# app/services/inline_editing/policy.rb
# frozen_string_literal: true

module InlineEditing
  class Policy
    def initialize(admin_user:, account:)
      @admin_user = admin_user
      @account = account
    end

    def permitted?(field)
      return false unless admin_user&.persisted? && account&.persisted?
      return true if field == "status"

      field == "region" && account.status == "active"
    end

    private

    attr_reader :account, :admin_user
  end
end
