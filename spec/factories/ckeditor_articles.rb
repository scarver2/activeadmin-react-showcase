# spec/factories/ckeditor_articles.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :ckeditor_article do
    association :admin_user
    body_html { "<p>A Rails-owned CKEditor document.</p>" }
    sequence(:title) { |number| "CKEditor article #{number}" }
    summary { "A concise description owned by an ordinary ActiveAdmin form." }
  end
end
