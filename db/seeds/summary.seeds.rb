# db/seeds/summary.seeds.rb
# frozen_string_literal: true

after :accounts, :activity_center, :audit_history, :calendar, :ckeditor, :content, :content_builder, :geospatial, :hierarchy, :material_studio, :message_preview, :operator_chat, :social_graph, :workflow do
  admin_email = ENV.fetch("SHOWCASE_ADMIN_EMAIL", "admin@example.test")
  preview_message_count = PreviewMessage.count
  puts "Seeded #{Account.count} accounts, #{Contact.count} contacts, #{DailyMetric.count} daily metrics, " \
       "#{ActivityNotification.count} activity notifications, #{ShowcaseArticle.count} Lexical article, " \
       "#{CkeditorArticle.count} CKEditor article, " \
       "#{ShowcaseAsset.count} assets, #{ScheduleEvent.count} calendar events, #{ContentBlock.count} content blocks, " \
       "#{HierarchyNode.count} hierarchy nodes, " \
       "#{ShowcaseLocation.count} locations, #{ChatMessage.count} chat messages, " \
       "#{MaterialSphere.count} material #{'sphere'.pluralize(MaterialSphere.count)}, " \
       "#{preview_message_count} preview #{'message'.pluralize(preview_message_count)}, " \
       "#{PaperTrail::Version.count} audit versions, " \
       "#{SocialPerson.count} social people, " \
       "and #{WorkflowItem.count} workflow items for #{admin_email}."
end
