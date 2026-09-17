# app/services/content_builder/seed.rb
# frozen_string_literal: true

module ContentBuilder
  class Seed
    def self.call(admin_user:)
      document = admin_user.content_documents.find_or_create_by!(title: "Mission briefing")
      return document if document.content_blocks.exists?
      [ [ "heading", "Explore the showcase" ], [ "paragraph", "Rails validates this normalized document." ], [ "callout", "Drag or use the move buttons." ] ].each_with_index do |(type, body), position|
        document.content_blocks.create!(block_type: type, body:, position:)
      end
      document
    end
  end
end
