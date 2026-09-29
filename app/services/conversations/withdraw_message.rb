# app/services/conversations/withdraw_message.rb
# frozen_string_literal: true

module Conversations
  class WithdrawMessage
    class WithdrawalNotAllowed < StandardError; end

    def self.call(message:, membership:, at: nil)
      message.with_lock do
        message.reload
        raise WithdrawalNotAllowed unless message.author == membership

        return message if message.withdrawn?

        effective_at = at || Time.current
        raise WithdrawalNotAllowed unless message.editable_by?(membership, at: effective_at)

        message.update!(body: Message::WITHDRAWN_BODY, withdrawn_at: effective_at)
      end
      message
    end
  end
end
