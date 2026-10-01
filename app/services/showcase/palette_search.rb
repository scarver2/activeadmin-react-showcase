# app/services/showcase/palette_search.rb
# frozen_string_literal: true

module Showcase
  class PaletteSearch
    def initialize(admin_user:, query: nil, recent: [])
      @admin_user = admin_user
      @search = GlobalSearch.new(admin_user:, query:).as_json
      @recent = Array(recent).first(5)
    end

    def as_json
      query = search.fetch(:query)
      records = search.fetch(:results).sort_by { |item| item.fetch(:kind) == "Page" ? 0 : 1 }.map { |item| navigable(item) }
      recents = recent.filter_map do |reference|
        item = resolve(reference.fetch("kind", ""), reference.fetch("id", ""))
        next unless item.fetch(:label).downcase.include?(query.downcase)

        item.merge(id: "recent-#{item.fetch(:id)}", kind: "Recent", group: "Recent context", description: "Recently opened from your palette")
      rescue ActiveRecord::RecordNotFound, KeyError
        nil
      end
      { query:, results: records + recents + PaletteCommands.new(admin_user:).search(query) }
    end

    def resolve(kind, id)
      item = case kind
      when "Account"
        record = Account.find(id)
        { label: record.name, url: Rails.application.routes.url_helpers.admin_account_path(record) }
      when "Article"
        record = ShowcaseArticle.find(id)
        { label: record.title, url: Rails.application.routes.url_helpers.admin_showcase_article_path(record) }
      when "Page"
        tool = WorkspaceCatalog.groups.flat_map { |group| group.fetch(:tools) }.find { |entry| entry.fetch(:url) == id }
        raise ActiveRecord::RecordNotFound unless tool

        { label: tool.fetch(:label), url: tool.fetch(:url) }
      else raise ActiveRecord::RecordNotFound
      end
      navigable(item.merge(id: "#{kind.downcase}-#{id}", kind:, description: kind))
    end

    private

    attr_reader :admin_user, :recent, :search

    def navigable(item)
      kind = item.fetch(:kind)
      id = item.fetch(:id).delete_prefix("#{kind.downcase}-")
      item.merge(group: kind == "Page" ? "Navigation" : "Records", visitUrl: Rails.application.routes.url_helpers.admin_palette_visit_path(kind:, id:))
    end
  end
end
