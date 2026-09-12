# spec/factories/content_documents.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :content_document do
    admin_user
    sequence(:title) { |number| "Document #{number}" }
  end
  factory :content_block do
    content_document
    block_type { "paragraph" }
    body { "Synthetic content" }
    position { 0 }
  end
end
