# spec/factories/tiny_mce_articles.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :tiny_mce_article do
    association :admin_user
    body_html { "<h2>Shift briefing</h2><p>Rails owns the persisted document.</p>" }
    sequence(:title) { |number| "TinyMCE article #{number}" }
    summary { "A self-hosted rich-text editor over an ordinary Rails textarea." }
  end
end
