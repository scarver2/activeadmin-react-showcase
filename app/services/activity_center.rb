# app/services/activity_center.rb
# frozen_string_literal: true

module ActivityCenter
  ATTENTION_KINDS = %w[fyi requires_action].freeze
  KINDS = %w[account conversation operation schedule].freeze
  PRIORITIES = %w[normal high].freeze

  class InvalidState < StandardError; end
  class UnsupportedAction < StandardError; end
end
