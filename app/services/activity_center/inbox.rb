# app/services/activity_center/inbox.rb
# frozen_string_literal: true

module ActivityCenter
  class Inbox
    FILTERS = %w[all dismissed fyi requires_action snoozed unread].freeze

    def initialize(admin_user:, now: Time.current)
      @admin_user = admin_user
      @now = now
    end

    def notifications(filter: "all")
      raise ArgumentError, "unsupported notification filter" unless filter.in?(FILTERS)

      filtered(filter).includes(event: :record).newest_first.limit(100)
    end

    def unread_count
      active.unread.count
    end

    private

    attr_reader :admin_user, :now

    def active
      admin_user.notifications
                .where(dismissed_at: nil)
                .where("snoozed_until IS NULL OR snoozed_until <= ?", now)
    end

    def filtered(filter)
      case filter
      when "all" then active
      when "dismissed" then admin_user.notifications.where.not(dismissed_at: nil)
      when "fyi", "requires_action" then active.where(attention_kind: filter)
      when "snoozed" then admin_user.notifications.where(dismissed_at: nil).where("snoozed_until > ?", now)
      when "unread" then active.unread
      end
    end
  end
end
