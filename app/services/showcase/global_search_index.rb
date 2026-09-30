# app/services/showcase/global_search_index.rb
# frozen_string_literal: true

module Showcase
  # Repairs the application-owned Active Search indexes from their authoritative Rails records.
  class GlobalSearchIndex
    BATCH_SIZE = 500
    INDEXES = {
      accounts: { document_class: AccountDocument, model_class: Account, source_key: :account_id },
      showcase_articles: {
        document_class: ShowcaseArticleDocument,
        model_class: ShowcaseArticle,
        source_key: :showcase_article_id
      }
    }.freeze

    def self.rebuild!
      new.rebuild!
    end

    def rebuild!
      INDEXES.each do |index_name, definition|
        rebuild_index(index_name, **definition)
      end

      nil
    end

    private

    def rebuild_index(index_name, document_class:, model_class:, source_key:)
      index = ActiveSearch.index(index_name)
      indexed_ids = document_class.order(:id).pluck(source_key)
      source_ids = model_class.where(id: indexed_ids).pluck(:id).map(&:to_s)
      stale_ids = indexed_ids.map(&:to_s) - source_ids

      index.batch(max_size: BATCH_SIZE) do |batch|
        stale_ids.each { |id| batch.remove_by_id(id) }
        model_class.find_each { |record| batch.add(record) }
      end
    end
  end
end
