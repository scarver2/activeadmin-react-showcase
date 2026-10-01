# app/services/showcase/global_search.rb
# frozen_string_literal: true

module Showcase
  class GlobalSearch
    class Unauthorized < StandardError; end

    CANDIDATE_LIMIT = 25
    MAXIMUM_QUERY_LENGTH = 80
    MAXIMUM_RESULTS = 8
    RESOURCE_ORDER = { "Page" => 0, "Account" => 1, "Article" => 2 }.freeze

    def initialize(admin_user:, query: nil)
      raise Unauthorized, "an authenticated administrator is required" unless admin_user&.persisted?

      @admin_user = admin_user
      @query = normalize_query(query)
    end

    def as_json
      { query:, results: ranked_results }
    end

    private

    attr_reader :admin_user, :query

    # The showcase currently grants every persisted administrator access to every synthetic
    # Account and ShowcaseArticle. Keep those relations explicit so future row-level policies are
    # applied before Active Search records leave the Rails boundary.
    def authorized_accounts
      Account.all
    end

    def authorized_articles
      ShowcaseArticle.all
    end

    def page_results
      WorkspaceCatalog.groups.flat_map do |group|
        group.fetch(:tools).filter_map do |tool|
          result_for(
            description: "#{group.fetch(:label)} · #{tool.fetch(:description)}",
            id: tool.fetch(:url),
            kind: "Page",
            label: tool.fetch(:label),
            searchable_text: [ tool.fetch(:label), tool.fetch(:description), group.fetch(:label) ],
            url: tool.fetch(:url)
          )
        end
      end
    end

    def account_results
      durable_records.accounts.filter_map do |account|
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
      durable_records.articles.filter_map do |article|
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

    def durable_records
      @durable_records ||= GlobalSearchRecords.new(
        account_scope: authorized_accounts,
        article_scope: authorized_articles,
        query:,
        limit: CANDIDATE_LIMIT
      )
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

      (page_results + account_results + article_results)
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
