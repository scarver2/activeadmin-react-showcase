# app/services/showcase/global_search.rb
# frozen_string_literal: true

module Showcase
  class GlobalSearch
    class Unauthorized < StandardError; end

    CANDIDATE_LIMIT = 25
    MAXIMUM_QUERY_LENGTH = 80
    MAXIMUM_RESULTS = 8
    RESOURCE_ORDER = { "Account" => 0, "Article" => 1 }.freeze

    def initialize(admin_user:, query: nil)
      raise Unauthorized, "an authenticated administrator is required" unless admin_user&.persisted?

      @query = normalize_query(query)
    end

    def as_json
      { query:, results: ranked_results }
    end

    private

    attr_reader :query

    def account_results
      Account.ransack(name_i_cont: query).result.order(:id).limit(CANDIDATE_LIMIT).filter_map do |account|
        result_for(
          description: "#{account.plan} · #{account.region} · #{account.status.capitalize}",
          id: account.id,
          kind: "Account",
          label: account.name,
          searchable_text: [ account.name ],
          url: Rails.application.routes.url_helpers.admin_account_path(account)
        )
      end
    end

    def article_results
      ShowcaseArticle.ransack(title_or_summary_i_cont: query).result.order(:id).limit(CANDIDATE_LIMIT).filter_map do |article|
        result_for(
          description: article.summary.presence || "Showcase article",
          id: article.id,
          kind: "Article",
          label: article.title,
          searchable_text: [ article.title, article.summary ],
          url: Rails.application.routes.url_helpers.admin_showcase_article_path(article)
        )
      end
    end

    def match_rank(values)
      normalized_values = values.compact.map { |value| value.downcase }
      return 0 if normalized_values.include?(query.downcase)
      return 1 if normalized_values.any? { |value| value.start_with?(query.downcase) }

      2
    end

    def normalize_query(value)
      return "" if value.nil?
      raise ArgumentError, "query must be text" unless value.is_a?(String)

      normalized = value.squish
      raise ArgumentError, "query must not exceed #{MAXIMUM_QUERY_LENGTH} characters" if normalized.length > MAXIMUM_QUERY_LENGTH

      normalized
    end

    def ranked_results
      return [] if query.blank?

      (account_results + article_results)
        .sort_by { |result| [ result.fetch(:rank), RESOURCE_ORDER.fetch(result.fetch(:kind)), result.fetch(:label).downcase, result.fetch(:id) ] }
        .first(MAXIMUM_RESULTS)
        .map { |result| result.except(:rank) }
    end

    def result_for(description:, id:, kind:, label:, searchable_text:, url:)
      return unless searchable_text.compact.any? { |value| value.downcase.include?(query.downcase) }

      { description:, id: "#{kind.downcase}-#{id}", kind:, label:, rank: match_rank(searchable_text), url: }
    end
  end
end
