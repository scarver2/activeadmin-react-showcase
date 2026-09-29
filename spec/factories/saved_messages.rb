# spec/factories/saved_messages.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :saved_message do
    message
    conversation { message.conversation }
    membership { association(:conversation_membership, conversation:) }
  end
end
