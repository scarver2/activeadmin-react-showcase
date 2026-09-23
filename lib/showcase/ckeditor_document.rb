# lib/showcase/ckeditor_document.rb
# frozen_string_literal: true

module Showcase
  module CkeditorDocument
    ALLOWED_ATTRIBUTES = %w[href title].freeze
    ALLOWED_TAGS = %w[a blockquote br code em h2 h3 li ol p pre strong ul].freeze
    MAX_BYTES = 50.kilobytes

    module_function

    def sanitize(html)
      ActionController::Base.helpers.sanitize(
        html.to_s,
        tags: ALLOWED_TAGS,
        attributes: ALLOWED_ATTRIBUTES
      ).to_s.strip
    end
  end
end
