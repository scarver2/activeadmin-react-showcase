# spec/factories/message_dispositions.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :message_disposition do
    message
    conversation { message.conversation }
    membership { association(:conversation_membership, conversation:) }
    kind { "like" }
  end
end
