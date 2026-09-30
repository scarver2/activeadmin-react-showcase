# spec/services/conversations/message_signals_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation message signals" do
  def concurrently(count, &block)
    ready = Queue.new
    start = Queue.new
    threads = count.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          block.call
        end
      end
    end
    count.times { ready.pop }
    count.times { start << true }
    threads.map(&:value)
  end

  let(:conversation) { create(:conversation) }
  let(:author) { create(:conversation_membership, conversation:, display_name: "Álvaro") }
  let(:viewer) { create(:conversation_membership, conversation:, display_name: "李 雷") }

  describe Conversations::CreateMessage do
    it "persists same-conversation replies and server-derived Unicode mentions" do
      original = described_class.call(conversation:, membership: author, body: "Original")

      reply = described_class.call(
        conversation:,
        membership: author,
        body: "Hello there",
        mentioned_memberships: [ viewer, viewer ],
        reply_to: original
      )

      expect(reply.reply_to_message).to eq(original)
      expect(reply.mentions.sole).to have_attributes(
        conversation:,
        mentioned_membership: viewer,
        mention_text: "@李 雷"
      )
    end

    it "rejects forged reply and mention targets outside the actor's conversation" do
      outsider = create(:conversation_membership, display_name: "Outsider")
      foreign_message = create(
        :message,
        conversation: outsider.conversation,
        conversation_membership: outsider
      )

      expect do
        described_class.call(
          conversation:,
          membership: author,
          body: "Forged reply",
          mentioned_memberships: [ viewer ],
          reply_to: foreign_message
        )
      end.to raise_error(Conversations::CreateMessage::NotAuthorized)
      expect do
        described_class.call(
          conversation:,
          membership: author,
          body: "Forged mention",
          mentioned_memberships: [ outsider ]
        )
      end.to raise_error(Conversations::CreateMessage::NotAuthorized)
      expect(conversation.messages).to be_empty
    end

    it "rejects a forged creator membership before opening the write transaction" do
      expect do
        described_class.call(
          conversation:,
          membership: create(:conversation_membership),
          body: "Forged author"
        )
      end.to raise_error(Conversations::CreateMessage::NotAuthorized)
      expect(conversation.messages).to be_empty
    end
  end

  describe Conversations::SetDisposition do
    let(:message) { Conversations::CreateMessage.call(conversation:, membership: author, body: "Decide") }

    it "sets, replays, changes and removes one explicit selection idempotently" do
      first = described_class.call(message:, membership: viewer, kind: "like")
      replay = described_class.call(message:, membership: viewer, kind: "like")
      changed = described_class.call(message:, membership: viewer, kind: "question")

      expect(replay).to eq(first)
      expect(changed).to eq(first)
      expect(message.dispositions.reload.sole).to have_attributes(kind: "question", membership: viewer)
      expect { described_class.call(message:, membership: viewer, kind: nil) }
        .to change { message.dispositions.reload.count }.from(1).to(0)
      expect { described_class.call(message:, membership: viewer, kind: nil) }
        .not_to(change { message.dispositions.reload.count })
    end

    it "rejects unsupported dispositions and forged membership authority" do
      outsider = create(:conversation_membership)

      expect { described_class.call(message:, membership: viewer, kind: "celebrate") }
        .to raise_error(ArgumentError, "unsupported disposition")
      expect { described_class.call(message:, membership: outsider, kind: "like") }
        .to raise_error(Conversations::SetDisposition::NotAuthorized)
    end

    it "serializes replayed concurrent selections without leaking uniqueness failures",
       database_cleaner: :truncation do
      dispositions = concurrently(4) do
        described_class.call(
          message: Message.find(message.id),
          membership: ConversationMembership.find(viewer.id),
          kind: "like"
        )
      end

      expect(dispositions.map(&:id).uniq.one?).to be(true)
      expect(message.dispositions.reload.sole).to have_attributes(kind: "like", membership_id: viewer.id)
    end

    it "makes concurrent removals safe and idempotent", database_cleaner: :truncation do
      described_class.call(message:, membership: viewer, kind: "dislike")

      expect do
        concurrently(2) do
          described_class.call(
            message: Message.find(message.id),
            membership: ConversationMembership.find(viewer.id),
            kind: nil
          )
        end
      end.not_to raise_error
      expect(message.dispositions.reload).to be_empty
    end
  end

  describe Conversations::MessageSnapshot do
    it "derives counts, current selection and structured mention identities from Rails truth" do
      message = Conversations::CreateMessage.call(
        conversation:,
        membership: author,
        body: "Hello",
        mentioned_memberships: [ viewer ]
      )
      Conversations::SetDisposition.call(message:, membership: author, kind: "like")
      Conversations::SetDisposition.call(message:, membership: viewer, kind: "question")

      payload = described_class.new(message, viewer_membership: viewer).as_json

      expect(payload).to include(id: message.public_id, sequence: message.sequence, body: "Hello", withdrawn: false)
      expect(payload.fetch(:mentions)).to eq([ { memberKey: viewer.key, text: "@李 雷" } ])
      expect(payload.fetch(:dispositions)).to eq(
        counts: { "like" => 1, "dislike" => 0, "question" => 1 },
        mine: "question"
      )
    end

    it "keeps replies resolvable while masking a withdrawn source as a tombstone" do
      original = Conversations::CreateMessage.call(conversation:, membership: author, body: "Sensitive")
      reply = Conversations::CreateMessage.call(
        conversation:,
        membership: viewer,
        body: "Acknowledged",
        reply_to: original
      )
      Conversations::WithdrawMessage.call(message: original, membership: author)

      reply_payload = described_class.new(reply.reload, viewer_membership: viewer).as_json.fetch(:replyTo)

      expect(reply_payload).to include(
        id: original.public_id,
        body: Message::WITHDRAWN_BODY,
        withdrawn: true
      )
    end

    it "rejects snapshots for a membership outside the conversation" do
      message = Conversations::CreateMessage.call(conversation:, membership: author, body: "Private")

      expect { described_class.new(message, viewer_membership: create(:conversation_membership)) }
        .to raise_error(Conversations::MessageSnapshot::NotAuthorized)
    end
  end
end
