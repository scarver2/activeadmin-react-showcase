# app/services/showcase/analytics_snapshot.rb
# frozen_string_literal: true

module Showcase
  class AnalyticsSnapshot
    MAXIMUM_DAYS = 90

    def initialize(start_date:, end_date:)
      @start_date = start_date
      @end_date = end_date

      validate_range!
    end

    def as_json
      metrics = DailyMetric.includes(:account).where(recorded_on: start_date..end_date).to_a

      {
        accounts: accounts(metrics),
        kpis: kpis(metrics),
        plans: plans(metrics),
        range: { endDate: end_date.iso8601, startDate: start_date.iso8601 },
        series: series(metrics)
      }
    end

    private

    attr_reader :end_date, :start_date

    def accounts(metrics)
      metrics.group_by(&:account).map do |account, account_metrics|
        {
          activeUsers: account_metrics.sum(&:active_users),
          name: account.name,
          revenueCents: account_metrics.sum(&:revenue_cents)
        }
      end.sort_by { |account| account.fetch(:name) }
    end

    def kpis(metrics)
      requests = metrics.sum(&:request_count)
      errors = metrics.sum(&:error_count)

      {
        activeUsers: metrics.sum(&:active_users),
        errorRate: requests.zero? ? 0.0 : ((errors.to_f / requests) * 100).round(2),
        p95Ms: metrics.empty? ? 0 : (metrics.sum(&:p95_ms).to_f / metrics.length).round,
        revenueCents: metrics.sum(&:revenue_cents)
      }
    end

    def plans(metrics)
      metrics.map(&:account).uniq.group_by(&:plan).sort.map do |name, accounts|
        { name:, value: accounts.length }
      end
    end

    def series(metrics)
      metrics.group_by(&:recorded_on).sort.map do |date, day_metrics|
        {
          activeUsers: day_metrics.sum(&:active_users),
          date: date.iso8601,
          requestCount: day_metrics.sum(&:request_count),
          revenueCents: day_metrics.sum(&:revenue_cents)
        }
      end
    end

    def validate_range!
      raise ArgumentError, "start_date must not be after end_date" if start_date > end_date
      raise ArgumentError, "date range must not exceed #{MAXIMUM_DAYS} days" if (end_date - start_date).to_i >= MAXIMUM_DAYS
    end
  end
end
