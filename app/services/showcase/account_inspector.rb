# app/services/showcase/account_inspector.rb
# frozen_string_literal: true

module Showcase
  class AccountInspector
    def initialize(account:, can_edit:)
      @account = account
      @can_edit = can_edit
    end

    def as_json
      {
        actions: actions,
        account: account_attributes,
        canonicalHref: routes.admin_account_path(account),
        metrics: metric_attributes,
        relationships: relationship_attributes
      }
    end

    private

    attr_reader :account, :can_edit

    def account_attributes
      account.slice(:id, :name, :plan, :region, :status).transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def actions
      actions = [ { href: routes.admin_account_path(account), label: "View full account" } ]
      actions << { href: routes.edit_admin_account_path(account), label: "Edit account" } if can_edit
      actions
    end

    def latest_metric
      @latest_metric ||= account.daily_metrics.order(recorded_on: :desc, id: :desc).first
    end

    def metric_attributes
      {
        activeUsers: latest_metric&.active_users || 0,
        recordedOn: latest_metric&.recorded_on&.iso8601,
        revenueCents: latest_metric&.revenue_cents || 0
      }
    end

    def relationship_attributes
      {
        contacts: account.contacts.count,
        observations: account.daily_metrics.count
      }
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end
