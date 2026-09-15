# lib/showcase/lexical_document.rb
# frozen_string_literal: true

require "erb"
require "json"
require "uri"

module Showcase
  # Validates and renders the canonical Lexical JSON document on the server.
  class LexicalDocument
    ALLOWED_LINK_PROTOCOLS = %w[http https mailto].freeze
    BLOCK_TYPES = %w[heading list paragraph quote].freeze
    MAX_JSON_BYTES = 100_000
    MAX_LINK_BYTES = 2_048
    TEXT_FORMATS = { 1 => "strong", 2 => "em", 8 => "u", 16 => "code" }.freeze

    class InvalidDocument < StandardError; end

    def self.empty_json
      from_plain_text("").fetch(:editor_state)
    end

    def self.from_plain_text(value)
      text = value.to_s
      lines = text.empty? ? [ "" ] : text.split(/\r?\n/, -1)
      children = lines.map do |line|
        {
          "children" => [ text_node(line) ],
          "direction" => nil,
          "format" => "",
          "indent" => 0,
          "type" => "paragraph",
          "version" => 1
        }
      end
      state = { "root" => { "children" => children, "direction" => nil, "format" => "", "indent" => 0,
                             "type" => "root", "version" => 1 } }
      editor_state = JSON.generate(state)

      { editor_state:, rendered_html: render_html(editor_state) }
    end

    def self.normalize(value)
      serialized = value.to_s
      raise InvalidDocument if serialized.bytesize > MAX_JSON_BYTES

      document = JSON.parse(serialized)
      validate_root(document.fetch("root"))
      JSON.generate(document)
    rescue JSON::ParserError, KeyError, TypeError
      raise InvalidDocument
    end

    def self.render_html(value)
      document = JSON.parse(normalize(value))

      document.fetch("root").fetch("children").map { |node| render_node(node) }.join
    end

    def self.to_plain_text(value)
      document = JSON.parse(normalize(value))

      document.fetch("root").fetch("children").map { |node| plain_text_for(node) }.join("\n")
    end

    def self.validate_node(node)
      raise InvalidDocument unless node.is_a?(Hash)

      case node["type"]
      when "heading"
        raise InvalidDocument unless %w[h2 h3].include?(node["tag"])

        validate_children(node)
      when "linebreak"
        nil
      when "link"
        validate_link(node.fetch("url"))
        validate_children(node)
      when "list"
        raise InvalidDocument unless %w[bullet number].include?(node["listType"])

        validate_children(node, allowed_types: [ "listitem" ])
      when "listitem"
        validate_children(node)
      when "paragraph", "quote"
        validate_children(node)
      when "text"
        raise InvalidDocument unless node["text"].is_a?(String)
        raise InvalidDocument unless node.fetch("format", 0).is_a?(Integer)
        raise InvalidDocument unless (node.fetch("format", 0) & ~TEXT_FORMATS.keys.sum).zero?
      else
        raise InvalidDocument
      end
    rescue KeyError
      raise InvalidDocument
    end

    def self.validate_root(root)
      raise InvalidDocument unless root.is_a?(Hash) && root["type"] == "root" && root["children"].is_a?(Array)
      raise InvalidDocument if root.fetch("children").empty?
      raise InvalidDocument if root.fetch("children").any? { |child| !BLOCK_TYPES.include?(child["type"]) }

      root.fetch("children").each { |child| validate_node(child) }
    end

    def self.validate_children(node, allowed_types: nil)
      children = node["children"]
      raise InvalidDocument unless children.is_a?(Array)
      raise InvalidDocument if allowed_types && children.any? { |child| !allowed_types.include?(child["type"]) }

      children.each { |child| validate_node(child) }
    end

    def self.validate_link(value)
      url = value.to_s
      raise InvalidDocument if url.empty? || url.bytesize > MAX_LINK_BYTES || url.match?(/[\u0000-\u001F\u007F]/)
      return if url.start_with?("#")
      return if url.start_with?("/") && !url.start_with?("//")

      uri = URI.parse(url)
      raise InvalidDocument unless ALLOWED_LINK_PROTOCOLS.include?(uri.scheme&.downcase)
    rescue URI::InvalidURIError
      raise InvalidDocument
    end

    def self.render_node(node)
      children = -> { node.fetch("children", []).map { |child| render_node(child) }.join }

      case node.fetch("type")
      when "heading"
        tag = node.fetch("tag")
        "<#{tag}>#{children.call}</#{tag}>"
      when "linebreak"
        "<br>"
      when "link"
        url = ERB::Util.html_escape(node.fetch("url"))
        %(<a href="#{url}" rel="nofollow noopener noreferrer">#{children.call}</a>)
      when "list"
        tag = node.fetch("listType") == "number" ? "ol" : "ul"
        "<#{tag}>#{children.call}</#{tag}>"
      when "listitem"
        "<li>#{children.call}</li>"
      when "paragraph"
        "<p>#{children.call}</p>"
      when "quote"
        "<blockquote>#{children.call}</blockquote>"
      when "text"
        render_text(node)
      end
    end

    def self.render_text(node)
      html = ERB::Util.html_escape(node.fetch("text"))
      format = node.fetch("format", 0)
      TEXT_FORMATS.each { |bit, tag| html = "<#{tag}>#{html}</#{tag}>" if (format & bit).positive? }
      html
    end

    def self.plain_text_for(node)
      case node.fetch("type")
      when "linebreak"
        "\n"
      when "heading", "link", "list", "listitem", "paragraph", "quote"
        node.fetch("children").map { |child| plain_text_for(child) }.join
      when "text"
        node.fetch("text")
      end
    end

    def self.text_node(text)
      { "detail" => 0, "format" => 0, "mode" => "normal", "style" => "", "text" => text,
        "type" => "text", "version" => 1 }
    end

    private_class_method :plain_text_for, :render_node, :render_text, :text_node, :validate_children, :validate_link,
                         :validate_node, :validate_root
  end
end
