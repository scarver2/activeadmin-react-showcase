# db/seeds.rb
# frozen_string_literal: true

admin_email = ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test")
admin_password = ENV["SHOWCASE_ADMIN_PASSWORD"]

if admin_password.blank?
  raise "SHOWCASE_ADMIN_PASSWORD is required in production" if Rails.env.production?

  admin_password = "showcase-password"
end

admin = AdminUser.find_or_initialize_by(email: admin_email)
admin.update!(password: admin_password, password_confirmation: admin_password)

accounts = [
  [ "Bluebonnet Logistics", "Enterprise", "Central", "active" ],
  [ "Cedar Ridge Health", "Growth", "East", "active" ],
  [ "High Plains Supply", "Starter", "West", "trial" ],
  [ "Lone Star Fieldworks", "Enterprise", "Central", "active" ],
  [ "Pecan Street Labs", "Growth", "West", "active" ],
  [ "Trinity River Foods", "Growth", "East", "active" ]
].map do |name, plan, region, status|
  Account.find_or_initialize_by(name:).tap do |account|
    account.update!(plan:, region:, status:)
  end
end

random = Random.new(20_260_905)

accounts.each_with_index do |account, account_index|
  30.times do |days_ago|
    metric = DailyMetric.find_or_initialize_by(account:, recorded_on: Date.current - days_ago.days)
    active_users = 90 + (account_index * 47) + random.rand(0..35)
    requests = active_users * random.rand(28..42)

    metric.update!(
      active_users:,
      error_count: (requests * random.rand(0.001..0.009)).round,
      p95_ms: random.rand(110..390),
      request_count: requests,
      revenue_cents: 3_900_000 + (account_index * 825_000) + random.rand(0..250_000)
    )
  end
end

article = ShowcaseArticle.find_or_initialize_by(title: "Rich editing stays Rails-owned")
document = Showcase::LexicalDocument.from_plain_text(
  "This article is edited by Lexical and submitted through an ordinary ActiveAdmin form."
)
article.update!(
  editor_state: document.fetch(:editor_state),
  rendered_html: document.fetch(:rendered_html),
  summary: "A safe rich-text boundary demonstrated by one focused React island."
)

assets = ShowcaseAssets::Seed.call
chat_room = OperatorChat::Seed.call

puts "Seeded #{Account.count} accounts, #{DailyMetric.count} daily metrics, #{ShowcaseArticle.count} article, #{assets.count} assets, and #{chat_room.messages.count} chat messages for #{admin.email}."
