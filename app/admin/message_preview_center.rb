# app/admin/message_preview_center.rb
# frozen_string_literal: true

if !Rails.env.production?
  ActiveAdmin.register_page "Message Preview Center" do
    menu label: "Message Preview", parent: "Content", priority: 5

    content title: "Development Message & Document Preview" do
      messages = PreviewMessage.with_attached_attachments.order(created_at: :desc)
      panel("Demo") { para "Inspect deterministic development messages and bounded attachments. letter_opener_web remains the delivery mailbox; this page demonstrates safe rich preview boundaries." }
      react_component("MessagePreviewCenter", props: { messages: messages.map { |message| MessagePreview::Serializer.new(message).as_json } }, fallback: -> {
        safe_join(messages.map do |message|
          content_tag(:article) do
            safe_join([ content_tag(:h3, message.subject), content_tag(:p, "#{message.sender} → #{message.recipient}"), content_tag(:pre, message.text_body), content_tag(:ul) { safe_join(MessagePreview::Serializer.new(message).as_json.fetch(:attachments).map { |attachment| content_tag(:li, attachment[:url] ? link_to(attachment[:filename], attachment[:url]) : attachment[:filename]) }) } ])
          end
        end)
      })
      panel("Ruby") { para "Rails gates the surface by environment, sanitizes HTML, allowlists MIME types, bounds size, and generates Active Storage URLs." }
      panel("JavaScript") { para "React owns tabs, attachment selection, and preview presentation. Direct server URLs remain available without JavaScript." }
      panel("Architecture") { para link_to("Read the preview guide and upstream credit", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/message-preview.md") }
    end
  end
end
