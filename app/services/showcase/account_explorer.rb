# app/services/showcase/account_explorer.rb
# frozen_string_literal: true

module Showcase
  class AccountExplorer
    DEFAULT_PER_PAGE = 5
    DIRECTIONS = { "asc" => :asc, "desc" => :desc }.freeze
    MAXIMUM_PAGE = 100
    MAXIMUM_QUERY_LENGTH = 80
    PER_PAGE_OPTIONS = [ 5, 10, 20 ].freeze
    SORTS = {
      "name" => :name,
      "plan" => :plan,
      "region" => :region,
      "status" => :status
    }.freeze

    def initialize(direction: nil, page: nil, per_page: nil, plan: nil, query: nil, sort: nil, status: nil)
      @direction = choice(direction, DIRECTIONS, "direction", "asc")
      @page = bounded_integer(page, "page", default: 1, maximum: MAXIMUM_PAGE)
      @per_page = permitted_integer(per_page, "per_page", default: DEFAULT_PER_PAGE, permitted: PER_PAGE_OPTIONS)
      @plan = optional_choice(plan, Account::PLANS, "plan")
      @query = normalized_query(query)
      @sort = choice(sort, SORTS, "sort", "name")
      @status = optional_choice(status, Account::STATUSES, "status")
    end

    def as_json
      filtered = relation
      total = filtered.count

      {
        filters: { plans: Account::PLANS, statuses: Account::STATUSES },
        page:,
        perPage: per_page,
        rows: rows(filtered),
        sort: { direction: direction.to_s, field: sort.to_s },
        total:,
        totalPages: [ (total.to_f / per_page).ceil, 1 ].max
      }
    end

    private

    attr_reader :direction, :page, :per_page, :plan, :query, :sort, :status

    def bounded_integer(value, name, default:, maximum:)
      integer = integer(value, default:)
      raise ArgumentError, "#{name} must be between 1 and #{maximum}" unless integer.between?(1, maximum)

      integer
    end

    def choice(value, choices, name, default)
      key = value.presence || default
      choices.fetch(key.to_s) { raise ArgumentError, "#{name} is not supported" }
    end

    def integer(value, default:)
      return default if value.blank?

      Integer(value.to_s, 10)
    rescue ArgumentError
      raise ArgumentError, "value must be an integer"
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

    def permitted_integer(value, name, default:, permitted:)
      selected = integer(value, default:)
      raise ArgumentError, "#{name} is not supported" unless permitted.include?(selected)

      selected
    rescue ArgumentError => error
      raise error unless error.message == "value must be an integer"

      raise ArgumentError, "#{name} must be an integer"
    end

    def relation
      scope = Account.includes(:daily_metrics)
      scope = scope.ransack(name_cont: query).result if query.present?
      scope = scope.where(plan:) if plan
      scope = scope.where(status:) if status
      scope.order(sort => direction, id: :asc)
    end

    def rows(scope)
      scope.offset((page - 1) * per_page).limit(per_page).map do |account|
        metrics = account.daily_metrics

        {
          activeUsers: metrics.sum(&:active_users),
          href: Rails.application.routes.url_helpers.admin_account_path(account),
          id: account.id,
          name: account.name,
          plan: account.plan,
          region: account.region,
          revenueCents: metrics.sum(&:revenue_cents),
          status: account.status
        }
      end
    end
  end
end
