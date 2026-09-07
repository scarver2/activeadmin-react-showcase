# app/admin/operator_chat.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Operator Chat" do
  menu label: "Operator Chat", parent: "Collaboration", priority: 1

  content title: "Operator Chat" do
    room = OperatorChat::Seed.call
    messages = room.messages.includes(:author).order(:sequence).limit(100)
    routes = Rails.application.routes.url_helpers

    panel "Persisted conversation, live delivery" do
      para "Rails authorizes commands and persists a synthetic support handoff. Solid Cable transports replayable updates."
    end

    react_component(
      "OperatorChat",
      props: {
        roomId: room.public_id,
        roomName: room.name,
        createUrl: routes.admin_operator_chat_messages_path(room.public_id),
        resetUrl: routes.admin_operator_chat_reset_path(room.public_id),
        messages: messages.map { |message| OperatorChat::Serializer.new(message).as_json }
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "Messages remain readable and commands remain available without JavaScript."),
          content_tag(:ul) do
            safe_join(messages.map { |message| content_tag(:li, "#{message.author.display_name}: #{message.body}") })
          end,
          form_with(url: routes.admin_operator_chat_messages_path(room.public_id), method: :post) do |form|
            safe_join([ form.label(:body, "Message"), form.text_field(:body, maxlength: 500), form.submit("Send message") ])
          end,
          button_to("Reset synthetic conversation", routes.admin_operator_chat_reset_path(room.public_id), method: :post)
        ])
      },
      class: "mt-6"
    )
  end
end
