# spec/factories/message_mentions.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :message_mention do
    message
    conversation { message.conversation }
    mentioned_membership { association(:conversation_membership, conversation:) }
    mention_text { "@#{mentioned_membership.display_name}" }
  end
end
