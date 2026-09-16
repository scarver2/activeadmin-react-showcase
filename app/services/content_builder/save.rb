# app/services/content_builder/save.rb
# frozen_string_literal: true

module ContentBuilder
  class Save
    MAXIMUM_BLOCKS = 12
    def self.call(document:, blocks:, expected_lock_version:)
      raise ArgumentError, "At most #{MAXIMUM_BLOCKS} blocks are allowed" if blocks.length > MAXIMUM_BLOCKS
      document.with_lock do
        raise ActiveRecord::StaleObjectError.new(document, "update") unless document.lock_version == Integer(expected_lock_version)
        document.content_blocks.delete_all
        blocks.each_with_index do |attributes, position|
          values = attributes.to_h.symbolize_keys
          raise ArgumentError, "Unknown block attributes" unless values.keys.sort == %i[body type]
          document.content_blocks.create!(block_type: values.fetch(:type), body: values.fetch(:body), position:)
        end
        document.touch
      end
      document.reload
    end
  end
end
