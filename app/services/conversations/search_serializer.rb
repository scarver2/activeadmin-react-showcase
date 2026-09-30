# app/services/conversations/search_serializer.rb
# frozen_string_literal: true

module Conversations
  class SearchSerializer
    def self.call(result:)
      new(result:).as_json
    end

    def initialize(result:)
      @result = result
    end

    def as_json
      {
        limit: Search::LIMIT,
        query: result.query,
        results: result.entries.map { |entry| serialize_entry(entry) }
      }
    end

    private

    attr_reader :result

    def serialize_entry(entry)
      message = entry.message
      {
        authorName: message&.author&.display_name,
        conversationPublicId: entry.conversation.public_id,
        conversationTitle: entry.conversation.title,
        kind: entry.kind,
        messagePublicId: message&.public_id,
        occurredAt: entry.occurred_at.iso8601,
        summary: entry.summary,
        url: result_url(entry)
      }
    end

    def result_url(entry)
      routes.admin_conversation_path(
        entry.conversation.public_id,
        before: entry.message.present? ? entry.message.sequence + 1 : nil,
        anchor: entry.message.present? ? "message-#{entry.message.public_id}" : nil
      )
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end
