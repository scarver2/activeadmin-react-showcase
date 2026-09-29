# app/services/conversations/seed.rb
# frozen_string_literal: true

module Conversations
  class Seed
    class Disabled < StandardError; end

    CONVERSATION_ID = "release-coordination"
    MESSAGE_FIXTURES = [
      "The release candidate is ready for the final accessibility pass.",
      "I will verify the no-JavaScript workflow before approval. ✅"
    ].freeze

    def self.call(admin_user:)
      raise Disabled unless Availability.enabled?

      conversation = Conversation.find_or_create_by!(public_id: CONVERSATION_ID) do |record|
        record.title = "Release coordination"
        record.topic = "Durable handoff between the release and operations teams"
      end
      membership = authenticated_membership(conversation:, admin_user:)
      seed_messages(conversation:, membership:)
      conversation
    end

    def self.authenticated_membership(conversation:, admin_user:)
      conversation.memberships.find_or_initialize_by(admin_user:).tap do |membership|
        membership.assign_attributes(display_name: "You", key: "operator-#{admin_user.id}", legacy_identity: false)
        membership.save!
      end
    end
    private_class_method :authenticated_membership

    def self.seed_messages(conversation:, membership:)
      MESSAGE_FIXTURES.each_with_index do |body, index|
        public_id = "release-coordination-message-#{index + 1}"
        conversation.messages.find_or_create_by!(public_id:) do |message|
          message.assign_attributes(author: membership, body:, sequence: index + 1)
        end
      end
      membership.mark_read_through!(conversation.messages.find_by!(public_id: "release-coordination-message-1"))
    end
    private_class_method :seed_messages
  end
end
