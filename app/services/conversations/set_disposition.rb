# app/services/conversations/set_disposition.rb
# frozen_string_literal: true

module Conversations
  class SetDisposition
    class NotAuthorized < StandardError; end

    def self.call(message:, membership:, kind:)
      normalized_kind = kind.presence&.to_s
      unless normalized_kind.nil? || normalized_kind.in?(MessageDisposition::KINDS)
        raise ArgumentError, "unsupported disposition"
      end
      raise NotAuthorized unless membership.conversation_id == message.conversation_id

      message.with_lock do
        disposition = message.dispositions.find_by(membership:)
        return disposition if disposition&.kind == normalized_kind

        if normalized_kind.nil?
          disposition&.destroy!
          return nil
        end

        disposition ||= message.dispositions.build(
          conversation: message.conversation,
          membership:
        )
        disposition.update!(kind: normalized_kind)
        disposition
      end
    end
  end
end
