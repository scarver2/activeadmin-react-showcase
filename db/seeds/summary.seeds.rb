# db/seeds/summary.seeds.rb
# frozen_string_literal: true

after :accounts, :activity_center, :audit_history, :calendar, :content, :content_builder, :geospatial, :hierarchy, :operator_chat, :workflow do
  admin_email = ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test")
  puts "Seeded #{Account.count} accounts, #{Contact.count} contacts, #{DailyMetric.count} daily metrics, " \
       "#{ActivityNotification.count} activity notifications, #{ShowcaseArticle.count} article, " \
       "#{ShowcaseAsset.count} assets, #{ScheduleEvent.count} calendar events, #{ContentBlock.count} content blocks, " \
       "#{HierarchyNode.count} hierarchy nodes, " \
       "#{ShowcaseLocation.count} locations, #{ChatMessage.count} chat messages, #{PaperTrail::Version.count} audit versions, " \
       "and #{WorkflowItem.count} workflow items for #{admin_email}."
end
