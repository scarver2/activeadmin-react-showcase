# app/services/showcase/heritage_accounts_workspace.rb
# frozen_string_literal: true

module Showcase
  class HeritageAccountsWorkspace
    LIMIT = 8

    attr_reader :status

    def initialize(status: nil)
      requested_status = status.to_s
      @status = requested_status if Account::STATUSES.include?(requested_status)
    end

    def accounts
      relation = Account.order(:name, :id)
      relation = relation.where(status:) if status
      relation.limit(LIMIT).to_a
    end
  end
end
