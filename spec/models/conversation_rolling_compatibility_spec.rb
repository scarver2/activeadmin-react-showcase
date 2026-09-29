# spec/models/conversation_rolling_compatibility_spec.rb
# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20260928090000_promote_operator_chat_to_conversations")

RSpec.describe "Conversation rolling compatibility", database_cleaner: :truncation do
  around do |example|
    migration = PromoteOperatorChatToConversations.new
    migration.send(:drop_sqlite_rolling_triggers)
    migration.send(:create_sqlite_rolling_triggers)
    example.run
  ensure
    migration&.send(:drop_sqlite_rolling_triggers)
  end

  it "accepts the previous release's chat table writes while canonical models read them" do
    connection = ActiveRecord::Base.connection
    inserted_at = Time.current.change(usec: 0)
    timestamp = connection.quote(inserted_at)
    legacy_name = "L" * 121

    connection.execute(<<~SQL.squish)
      INSERT INTO chat_rooms (id, name, public_id, created_at, updated_at)
      VALUES (990001, #{connection.quote(legacy_name)}, 'rolling-room', #{timestamp}, #{timestamp})
    SQL
    connection.execute(<<~SQL.squish)
      INSERT INTO chat_participants (id, chat_room_id, display_name, key, created_at, updated_at)
      VALUES (990002, 990001, 'Legacy writer', 'legacy-writer', #{timestamp}, #{timestamp})
    SQL
    connection.execute(<<~SQL.squish)
      INSERT INTO chat_messages (id, author_id, body, chat_room_id, sequence, created_at, updated_at)
      VALUES (990003, 990002, 'Written by the prior image.', 990001, 1, #{timestamp}, #{timestamp})
    SQL

    conversation = Conversation.find(990001)
    membership = ConversationMembership.find(990002)
    message = Message.find(990003)

    expect(conversation).to have_attributes(title: legacy_name, public_id: "rolling-room")
    expect(conversation.last_activity_at).to be_within(1.second).of(inserted_at)
    expect(membership).to have_attributes(conversation:, legacy_identity: true, admin_user: nil)
    expect(message).to have_attributes(
      conversation:,
      conversation_membership: membership,
      public_id: "message-990003",
      sequence: 1
    )
  end
end
