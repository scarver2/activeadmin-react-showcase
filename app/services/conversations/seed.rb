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
      peer_membership = legacy_peer_membership(conversation:)
      messages = seed_messages(conversation:, membership:, peer_membership:)
      SetSavedState.call(message: messages.first, membership:, saved: true)
      seed_scheduled_messages(conversation:, membership:)
      conversation
    end

    def self.authenticated_membership(conversation:, admin_user:)
      conversation.memberships.find_or_initialize_by(admin_user:).tap do |membership|
        membership.assign_attributes(display_name: "You", key: "operator-#{admin_user.id}", legacy_identity: false)
        membership.save!
      end
    end
    private_class_method :authenticated_membership

    def self.legacy_peer_membership(conversation:)
      conversation.memberships.find_or_initialize_by(key: "release-lead").tap do |membership|
        membership.assign_attributes(admin_user: nil, display_name: "Release Lead", legacy_identity: true)
        membership.save!
      end
    end
    private_class_method :legacy_peer_membership

    def self.seed_messages(conversation:, membership:, peer_membership:)
      MESSAGE_FIXTURES.each_with_index do |body, index|
        public_id = "release-coordination-message-#{index + 1}"
        conversation.messages.find_or_create_by!(public_id:) do |message|
          author = index.zero? ? peer_membership : membership
          message.assign_attributes(author:, body:, sequence: index + 1)
        end
      end
      seed_attachment(conversation.messages.find_by!(public_id: "release-coordination-message-1"))
      membership.mark_read_through!(conversation.messages.find_by!(public_id: "release-coordination-message-1"))
      conversation.messages.order(:sequence).to_a
    end
    private_class_method :seed_messages

    def self.seed_scheduled_messages(conversation:, membership:)
      delivered_message = conversation.messages.find_or_create_by!(public_id: "release-coordination-scheduled-delivery") do |message|
        message.assign_attributes(
          author: membership,
          body: "The scheduled release reminder arrived on time.",
          sequence: conversation.messages.maximum(:sequence).to_i + 1
        )
      end
      ScheduledMessage.find_or_create_by!(public_id: "release-coordination-scheduled-delivered") do |scheduled_message|
        scheduled_message.assign_attributes(
          admin_user: membership.admin_user,
          body: delivered_message.body,
          conversation:,
          delivered_at: 1.hour.ago,
          delivered_message:,
          delivery_public_id: delivered_message.public_id,
          scheduled_for: 2.hours.ago,
          state: "delivered"
        )
      end
      pending = ScheduledMessage.find_or_initialize_by(public_id: "release-coordination-scheduled-pending")
      should_enqueue = pending.new_record?
      if should_enqueue
        pending.assign_attributes(
          admin_user: membership.admin_user,
          body: "Review the release health report tomorrow morning.",
          conversation:,
          scheduled_for: 1.day.from_now,
          state: "pending"
        )
        pending.save!
      end
      ScheduleMessage.enqueue(pending) if should_enqueue
    end
    private_class_method :seed_scheduled_messages

    def self.seed_attachment(message)
      return if message.attachment.present?

      Tempfile.create([ "release-checklist", ".txt" ]) do |file|
        file.write("Synthetic release checklist\n- accessibility\n- no-JavaScript workflow\n")
        file.rewind
        upload = ActionDispatch::Http::UploadedFile.new(
          filename: "release-checklist.txt",
          tempfile: file,
          type: "text/plain"
        )
        Conversations::AttachUpload.call(message:, upload:)
      end
    end
    private_class_method :seed_attachment
  end
end
