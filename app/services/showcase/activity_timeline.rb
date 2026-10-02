# app/services/showcase/activity_timeline.rb
# frozen_string_literal: true

module Showcase
  # Read-only projection: sources authorize before projection, unavailable
  # sources shed content, and signed cursors bind ordering to reader and filters.
  class ActivityTimeline
    PAGE_SIZE = 25
    GROUPS = %w[day family actor].freeze
    PATH = "/admin/activity_timeline"

    def initialize(admin_user:, params: {}, sources: TimelineSources.new)
      @admin_user = admin_user
      @params = params.to_h.stringify_keys
      @sources = sources
    end

    def page
      filters = normalized_filters
      events = sources.visible_records(admin_user:).map { |record| project(record) }
        .uniq { |event| event.fetch(:id) }
        .select { |event| matches?(event, filters) }
        .sort_by { |event| key(event) }.reverse
      cursor = params["cursor"].presence
      if cursor
        position = decode_cursor(cursor, filters)
        events = events.select { |event| (key(event) <=> position) == -1 }
      end
      items = events.first(PAGE_SIZE)
      next_cursor = if events.size > PAGE_SIZE
        verifier.generate({ "version" => TimelineSources::VERSION, "reader" => admin_user.id,
          "filters" => filters, "position" => key(items.last) }, purpose: "activity-timeline", expires_in: 1.hour)
      end
      { items:, filters:, nextUrl: next_cursor && url(filters.merge("cursor" => next_cursor)),
        startUrl: url(filters), pageSize: PAGE_SIZE }
    end

    def self.groups(items, group)
      items.group_by do |event|
        case group
        when "family" then TimelineSources::FAMILIES.fetch(event.fetch(:family)).fetch(:label)
        when "actor" then event.fetch(:actor)
        else event.fetch(:occurredAt).first(10)
        end
      end
    end

    private

    attr_reader :admin_user, :params, :sources

    def normalized_filters
      family = params["family"].to_s
      actor = params["actor"].to_s
      since = params["since"].to_s
      group = params["group"].presence || "day"
      raise ArgumentError, "Unknown event family" unless family.empty? || TimelineSources::FAMILIES.key?(family)
      raise ArgumentError, "Unknown actor" unless actor.empty? || (TimelineSources::ACTORS + [ "Unavailable" ]).include?(actor)
      raise ArgumentError, "Unknown grouping" unless GROUPS.include?(group)
      unless since.empty?
        raise ArgumentError, "Use a valid YYYY-MM-DD date" unless since.match?(/\A\d{4}-\d{2}-\d{2}\z/) && Date.iso8601(since).iso8601 == since
      end
      { "family" => family, "actor" => actor, "since" => since, "group" => group }
    end

    def project(record)
      available = record.fetch(:state) == "available"
      { id: record.fetch(:id), family: record.fetch(:family), occurredAt: record.fetch(:occurred_at),
        actor: available ? record.fetch(:actor) : "Unavailable", state: record.fetch(:state),
        summary: available ? record.fetch(:title) : "Source #{record.fetch(:state)} — details unavailable",
        details: available ? record.fetch(:fields) : {},
        sourceUrl: available ? url("source" => record.fetch(:id)) : nil }
    end

    def matches?(event, filters)
      (filters.fetch("family").empty? || event.fetch(:family) == filters.fetch("family")) &&
        (filters.fetch("actor").empty? || event.fetch(:actor) == filters.fetch("actor")) &&
        (filters.fetch("since").empty? || event.fetch(:occurredAt).first(10) >= filters.fetch("since"))
    end

    def key(event)
      [ event.fetch(:occurredAt), event.fetch(:id) ]
    end

    def verifier
      Rails.application.message_verifier("activity-timeline")
    end

    def decode_cursor(cursor, filters)
      data = verifier.verified(cursor, purpose: "activity-timeline") if cursor.is_a?(String) && cursor.bytesize <= 4096
      unless data && data["version"] == TimelineSources::VERSION && data["reader"] == admin_user.id && data["filters"] == filters &&
          data["position"].is_a?(Array) && data["position"].size == 2 && data["position"].all? { |part| part.is_a?(String) }
        raise ArgumentError, "Resume link expired or changed. Start again with these filters."
      end
      data.fetch("position")
    end

    def url(query)
      "#{PATH}?#{query.to_query}"
    end
  end
end
