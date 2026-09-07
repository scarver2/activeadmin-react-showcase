# app/services/showcase/relationship_explorer.rb
# frozen_string_literal: true

module Showcase
  class RelationshipExplorer
    MAXIMUM_QUERY_LENGTH = 80
    MAXIMUM_RESULTS = 20
    SEARCH_PREDICATE = :name_or_contacts_first_name_or_contacts_last_name_or_contacts_email_or_contacts_job_title_i_cont

    def initialize(plan: nil, query: nil, region: nil, relationship_role: nil, selected_id: nil)
      @plan = optional_choice(plan, Account::PLANS, "plan")
      @query = normalized_query(query)
      @region = optional_choice(region, Account::REGIONS, "region")
      @relationship_role = optional_choice(relationship_role, Contact::RELATIONSHIP_ROLES, "relationship_role")
      @selected_id = optional_integer(selected_id, "selected_id")
    end

    def as_json
      filtered = relation
      total = filtered.count
      accounts = filtered.limit(MAXIMUM_RESULTS).to_a
      selected = selected_account(accounts)

      {
        accounts: accounts.map { |account| account_summary(account) },
        filters: {
          plans: Account::PLANS,
          regions: Account::REGIONS,
          relationshipRoles: Contact::RELATIONSHIP_ROLES
        },
        selectedAccount: selected && account_detail(selected),
        total:,
        truncated: total > MAXIMUM_RESULTS
      }
    end

    private

    attr_reader :plan, :query, :region, :relationship_role, :selected_id

    def account_detail(account)
      account_summary(account).merge(
        contacts: account.contacts.sort_by { |contact| [ contact.last_name, contact.first_name ] }.map do |contact|
          {
            email: contact.email,
            fullName: contact.full_name,
            href: routes.admin_contact_path(contact),
            id: contact.id,
            jobTitle: contact.job_title,
            relationshipRole: contact.relationship_role
          }
        end,
        href: routes.admin_account_path(account)
      )
    end

    def account_summary(account)
      {
        contactCount: account.contacts.length,
        id: account.id,
        name: account.name,
        plan: account.plan,
        region: account.region,
        status: account.status
      }
    end

    def normalized_query(value)
      return "" if value.blank?
      raise ArgumentError, "query must be text" unless value.is_a?(String)
      raise ArgumentError, "query must not exceed #{MAXIMUM_QUERY_LENGTH} characters" if value.length > MAXIMUM_QUERY_LENGTH

      value.strip
    end

    def optional_choice(value, choices, name)
      return nil if value.blank?

      choices.include?(value.to_s) ? value.to_s : raise(ArgumentError, "#{name} is not supported")
    end

    def optional_integer(value, name)
      return nil if value.blank?

      integer = Integer(value.to_s, 10)
      raise ArgumentError, "#{name} must be positive" unless integer.positive?

      integer
    rescue ArgumentError => error
      raise error if error.message == "#{name} must be positive"

      raise ArgumentError, "#{name} must be an integer"
    end

    def relation
      scope = Account.includes(:contacts)
      scope = scope.ransack(SEARCH_PREDICATE => query).result(distinct: true) if query.present?
      scope = scope.where(plan:) if plan
      scope = scope.where(region:) if region
      scope = scope.joins(:contacts).where(contacts: { relationship_role: }).distinct if relationship_role
      scope.order(:name, :id)
    end

    def routes
      Rails.application.routes.url_helpers
    end

    def selected_account(accounts)
      return accounts.first unless selected_id

      accounts.find { |account| account.id == selected_id } ||
        raise(ArgumentError, "selected_id is not available in these filters")
    end
  end
end
