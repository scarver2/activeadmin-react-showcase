# spec/services/message_preview_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessagePreview do
  it "seeds deterministic allowlisted attachments idempotently" do
    message = MessagePreview::Seed.call
    expect(message.attachments.map(&:content_type)).to match_array(PreviewMessage::ALLOWED_TYPES.values_at(0, 1, 3))
    expect { MessagePreview::Seed.call }.not_to change(ActiveStorage::Attachment, :count)
  end

  it "sanitizes HTML and returns bounded preview strategies" do
    payload = MessagePreview::Serializer.new(MessagePreview::Seed.call).as_json
    expect(payload.fetch(:htmlBody)).not_to include("script")
    expect(payload.fetch(:attachments).pluck(:kind)).to match_array(%w[download image pdf])
  end

  it "omits unsupported and marks oversized attachments" do
    message = MessagePreview::Seed.call
    allow(message.attachments.first).to receive(:content_type).and_return("application/octet-stream")
    payload = MessagePreview::Serializer.new(message).as_json
    expect(payload.fetch(:attachments).length).to eq(2)
    allow(message.attachments.second).to receive(:byte_size).and_return(PreviewMessage::MAXIMUM_BYTES + 1)
    expect(MessagePreview::Serializer.new(message).as_json.fetch(:attachments)).to include(include(kind: "oversized"))
  end
end
