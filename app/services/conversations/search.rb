# app/services/conversations/search.rb
# frozen_string_literal: true

module Conversations
  class Search
    LIMIT = 50
    MAX_QUERY_LENGTH = 100

    Entry = Data.define(:conversation, :kind, :message, :occurred_at, :summary)
    Result = Data.define(:entries, :query)

    def self.call(admin_user:, query:)
      new(admin_user:, query:).call
    end

    def initialize(admin_user:, query:)
      @admin_user = admin_user
      @query = normalize(query)
    end

    def call
      return Result.new(entries: [], query:) if query.blank?

      entries = (conversation_entries + message_entries)
                .sort_by { |entry| sort_key(entry) }
                .first(LIMIT)

      Result.new(entries:, query:)
    end

    private

    attr_reader :admin_user, :query

    def conversation_entries
      conversations = Conversation.joins(:memberships)
                                  .where(chat_participants: { admin_user_id: admin_user.id })
                                  .where(conversation_match)
                                  .distinct
                                  .order(last_activity_at: :desc, id: :desc)
                                  .limit(LIMIT)

      conversations.map do |conversation|
        summary = [ conversation.title, conversation.topic ].compact.join(" — ")
        Entry.new(conversation:, kind: :conversation, message: nil, occurred_at: conversation.last_activity_at, summary:)
      end
    end

    def message_entries
      messages = Message.includes(:author, :conversation)
                        .joins(conversation: :memberships)
                        .where(chat_participants: { admin_user_id: admin_user.id })
                        .where(withdrawn_at: nil)
                        .where(message_match)
                        .distinct
                        .order(created_at: :desc, id: :desc)
                        .limit(LIMIT)

      messages.map do |message|
        Entry.new(
          conversation: message.conversation,
          kind: :message,
          message:,
          occurred_at: message.created_at,
          summary: message.body.truncate(180)
        )
      end
    end

    def conversation_match
      conversations = Conversation.arel_table
      lower(conversations[:name]).matches(pattern, "\\").or(lower(conversations[:topic]).matches(pattern, "\\"))
    end

    def message_match
      lower(Message.arel_table[:body]).matches(pattern, "\\")
    end

    def lower(attribute)
      Arel::Nodes::NamedFunction.new("LOWER", [ attribute ])
    end

    def normalize(value)
      return "" unless value.is_a?(String)

      value.unicode_normalize(:nfc).squish.first(MAX_QUERY_LENGTH)
    end

    def pattern
      @pattern ||= "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%"
    end

    def sort_key(entry)
      [ -entry.occurred_at.to_f, -entry.conversation.id, -(entry.message&.id || 0), entry.kind.to_s ]
    end
  end
end
