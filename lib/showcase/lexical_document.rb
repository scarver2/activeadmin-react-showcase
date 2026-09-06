# lib/showcase/lexical_document.rb
# frozen_string_literal: true

require "erb"
require "json"

module Showcase
  # Owns the server trust boundary for browser-produced Lexical documents.
  class LexicalDocument
    ALLOWED_ATTRIBUTES = %w[href rel target title].freeze
    ALLOWED_TAGS = %w[a br code em li ol p s strong u ul].freeze
    MAX_JSON_BYTES = 100_000

    class InvalidDocument < StandardError; end

    def self.empty_json
      from_plain_text("").fetch(:editor_state)
    end

    def self.from_plain_text(value)
      text = value.to_s
      lines = text.empty? ? [ "" ] : text.split(/\r?\n/, -1)
      children = lines.map do |line|
        {
          "children" => [ { "detail" => 0, "format" => 0, "mode" => "normal", "style" => "", "text" => line,
                            "type" => "text", "version" => 1 } ],
          "direction" => nil,
          "format" => "",
          "indent" => 0,
          "type" => "paragraph",
          "version" => 1
        }
      end
      state = { "root" => { "children" => children, "direction" => nil, "format" => "", "indent" => 0,
                             "type" => "root", "version" => 1 } }

      {
        editor_state: JSON.generate(state),
        rendered_html: sanitize_html(
          children.map { |node| "<p>#{ERB::Util.html_escape(node.dig("children", 0, "text"))}</p>" }.join
        )
      }
    end

    def self.normalize(value)
      serialized = value.to_s
      raise InvalidDocument if serialized.bytesize > MAX_JSON_BYTES

      document = JSON.parse(serialized)
      root = document.fetch("root")
      validate_root(root)

      JSON.generate(document)
    rescue JSON::ParserError, KeyError, TypeError
      raise InvalidDocument
    end

    def self.sanitize_html(value)
      Rails::HTML5::SafeListSanitizer.new.sanitize(
        value.to_s,
        attributes: ALLOWED_ATTRIBUTES,
        tags: ALLOWED_TAGS
      )
    end

    def self.validate_node(node)
      raise InvalidDocument unless node.is_a?(Hash)

      case node["type"]
      when "linebreak"
        nil
      when "paragraph"
        children = node["children"]
        raise InvalidDocument unless children.is_a?(Array)

        children.each { |child| validate_node(child) }
      when "text"
        raise InvalidDocument unless node["text"].is_a?(String)
      else
        raise InvalidDocument
      end
    end

    def self.validate_root(root)
      raise InvalidDocument unless root.is_a?(Hash) && root["type"] == "root" && root["children"].is_a?(Array)

      root.fetch("children").each { |child| validate_node(child) }
    end

    private_class_method :validate_node, :validate_root
  end
end
