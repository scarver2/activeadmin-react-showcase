# app/services/showcase/global_search_records.rb
# frozen_string_literal: true

module Showcase
  # Keeps Active Search replaceable behind the Global Search application contract.
  class GlobalSearchRecords
    MINIMUM_TRIGRAM_LENGTH = 3

    def initialize(query:, limit:)
      @limit = limit
      @query = query
    end

    def accounts
      candidates(
        indexed: -> { Account.search(query).limit(limit).results },
        short_query: -> { Account.ransack(name_i_cont: query).result.order(:id).limit(limit) }
      )
    end

    def articles
      candidates(
        indexed: -> { ShowcaseArticle.search(query).limit(limit).results },
        short_query: -> { ShowcaseArticle.ransack(title_or_summary_i_cont: query).result.order(:id).limit(limit) }
      )
    end

    private

    attr_reader :limit, :query

    def candidates(indexed:, short_query:)
      records = query.length < MINIMUM_TRIGRAM_LENGTH ? short_query.call : indexed.call
      records.to_a.sort_by(&:id).first(limit)
    end
  end
end
