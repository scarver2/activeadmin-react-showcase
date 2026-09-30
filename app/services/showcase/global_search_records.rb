# app/services/showcase/global_search_records.rb
# frozen_string_literal: true

module Showcase
  # Keeps Active Search replaceable behind the Global Search application contract.
  class GlobalSearchRecords
    MINIMUM_TRIGRAM_LENGTH = 3

    def initialize(account_scope: Account.all, article_scope: ShowcaseArticle.all, query:, limit:)
      @account_scope = account_scope
      @article_scope = article_scope
      @limit = limit
      @query = query
    end

    def accounts
      candidates(
        indexed: -> { Account.search(query, scope: account_scope).limit(limit).results },
        short_query: -> { account_scope.ransack(name_i_cont: query).result.order(:id).limit(limit) }
      )
    end

    def articles
      candidates(
        indexed: -> { ShowcaseArticle.search(query, scope: article_scope).limit(limit).results },
        short_query: -> { article_scope.ransack(title_or_summary_i_cont: query).result.order(:id).limit(limit) }
      )
    end

    private

    attr_reader :account_scope, :article_scope, :limit, :query

    def candidates(indexed:, short_query:)
      records = query.length < MINIMUM_TRIGRAM_LENGTH ? short_query.call : indexed.call
      records.to_a.sort_by(&:id).first(limit)
    end
  end
end
