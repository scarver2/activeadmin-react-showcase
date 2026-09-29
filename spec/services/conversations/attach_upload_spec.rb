# spec/services/conversations/attach_upload_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversations::AttachUpload do
  let(:conversation) { create(:conversation) }
  let(:membership) { create(:conversation_membership, conversation:) }
  let(:upload) { uploaded_file("sample.txt", "text/plain") }

  it "attaches one detected, sanitized, bounded file to the durable message" do
    upload = uploaded_file("sample.txt", "text/plain", filename: "../release notes?.txt")
    message = Conversations::CreateMessage.call(
      attachment: upload,
      body: "Review the attachment",
      conversation:,
      membership:
    )

    attachment = message.reload.attachment
    expect(attachment.file).to be_attached
    expect(attachment.file.filename.to_s).to eq("release-notes.txt")
    expect(attachment.file.content_type).to eq("text/plain")
    expect(attachment.file.download).to eq(File.binread(file_fixture("sample.txt")))
  end

  it "rejects content whose detected type is outside the allowlist without durable leakage" do
    unsafe = uploaded_file("unsafe.svg", "image/png")
    counts = record_counts

    expect do
      Conversations::CreateMessage.call(
        attachment: unsafe,
        body: "This must not persist",
        conversation:,
        membership:
      )
    end.to raise_error(described_class::InvalidUpload, /type is not allowed/)
    expect(record_counts).to eq(counts)
  end

  it "purges uploaded storage when a later message transaction step fails" do
    service = ActiveStorage::Blob.service
    allow(service).to receive(:delete).and_call_original
    allow(membership).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(membership))
    counts = record_counts

    expect do
      Conversations::CreateMessage.call(
        attachment: upload,
        body: "Rollback everything",
        conversation:,
        membership:
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect(record_counts).to eq(counts)
    expect(service).to have_received(:delete).once
  end

  it "rejects an oversized attachment before creating a blob or message" do
    tempfile = Tempfile.new([ "oversized", ".txt" ])
    tempfile.write("x" * (MessageAttachment::MAXIMUM_BYTES + 1))
    tempfile.rewind
    oversized = ActionDispatch::Http::UploadedFile.new(
      filename: "oversized.txt",
      tempfile:,
      type: "text/plain"
    )
    counts = record_counts

    expect do
      Conversations::CreateMessage.call(
        attachment: oversized,
        body: "Too large",
        conversation:,
        membership:
      )
    end.to raise_error(described_class::InvalidUpload, /1 MB or smaller/)
    expect(record_counts).to eq(counts)
  ensure
    tempfile&.close!
  end

  def record_counts
    [ Message.count, MessageAttachment.count, ActiveStorage::Attachment.count, ActiveStorage::Blob.count ]
  end

  def uploaded_file(fixture, content_type, filename: fixture)
    ActionDispatch::Http::UploadedFile.new(
      filename:,
      tempfile: File.open(file_fixture(fixture)),
      type: content_type
    )
  end
end
