# app/services/content_builder/serializer.rb
# frozen_string_literal: true

module ContentBuilder
  class Serializer
    def initialize(document)
      @document = document
    end
    def as_json
      { id: document.id.to_s, lockVersion: document.lock_version, title: document.title,
        updateUrl: Rails.application.routes.url_helpers.admin_content_builder_document_path(document),
        blocks: document.content_blocks.map { |block| { body: block.body, id: block.id.to_s, type: block.block_type } } }
    end
    private
    attr_reader :document
  end
end
