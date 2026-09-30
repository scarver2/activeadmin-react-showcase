# app/services/conversations/availability.rb
# frozen_string_literal: true

module Conversations
  class Availability
    def self.enabled?
      configured = ENV["SHOWCASE_CONVERSATIONS_ENABLED"]
      return !Rails.env.production? if configured.nil?

      configured == "true"
    end
  end
end
