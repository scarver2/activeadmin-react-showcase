# app/services/conversations/saved_messages.rb
# frozen_string_literal: true

require "base64"

module Conversations
  class SavedMessages
    LIMIT = 50
    Page = Data.define(:records, :older_cursor, :newer_cursor)
    Cursor = Data.define(:created_at, :id)

    def self.call(admin_user:, before: nil, after: nil)
      raise ArgumentError, "choose either before or after" if before.present? && after.present?

      new(admin_user:, before:, after:).call
    end

    def initialize(admin_user:, before:, after:)
      @admin_user = admin_user
      @before = decode(before)
      @after = decode(after)
    end

    def call
      records = page_relation.to_a
      records.reverse! if @after
      Page.new(
        records:,
        older_cursor: boundary_cursor(records.last, direction: :older),
        newer_cursor: boundary_cursor(records.first, direction: :newer)
      )
    end

    private

    def relation
      SavedMessage
        .joins(:membership)
        .where(chat_participants: { admin_user_id: @admin_user.id })
        .includes(:membership, :conversation, message: :author)
    end

    def page_relation
      scope = relation
      scope = older_than(scope, @before) if @before
      scope = newer_than(scope, @after) if @after
      scope.order(created_at: @after ? :asc : :desc, id: @after ? :asc : :desc).limit(LIMIT)
    end

    def boundary_cursor(record, direction:)
      return if record.nil?

      cursor = Cursor.new(created_at: record.created_at, id: record.id)
      scope = direction == :older ? older_than(relation, cursor) : newer_than(relation, cursor)
      encode(cursor) if scope.exists?
    end

    def older_than(scope, cursor)
      scope.where("saved_messages.created_at < :time OR (saved_messages.created_at = :time AND saved_messages.id < :id)",
                  time: cursor.created_at,
                  id: cursor.id)
    end

    def newer_than(scope, cursor)
      scope.where("saved_messages.created_at > :time OR (saved_messages.created_at = :time AND saved_messages.id > :id)",
                  time: cursor.created_at,
                  id: cursor.id)
    end

    def encode(cursor)
      Base64.urlsafe_encode64("#{cursor.created_at.iso8601(6)}\n#{cursor.id}", padding: false)
    end

    def decode(value)
      return if value.blank?

      timestamp, id = Base64.urlsafe_decode64(value).split("\n", 2)
      raise ArgumentError unless timestamp.present? && id&.match?(/\A[1-9]\d*\z/)

      Cursor.new(created_at: Time.iso8601(timestamp), id: Integer(id, 10))
    rescue ArgumentError
      raise ActiveRecord::RecordNotFound, "invalid saved-message cursor"
    end
  end
end
