# spec/services/content_builder_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentBuilder::Save do
  let(:document) { create(:content_document) }
  it "persists a normalized ordered projection and serializes it" do
    saved = described_class.call(document:, blocks: [ { type: "heading", body: "Hello" }, { type: "paragraph", body: "World" } ], expected_lock_version: 0)
    expect(saved.content_blocks.pluck(:block_type, :body, :position)).to eq([ [ "heading", "Hello", 0 ], [ "paragraph", "World", 1 ] ])
    expect(ContentBuilder::Serializer.new(saved).as_json).to include(title: saved.title, updateUrl: Rails.application.routes.url_helpers.admin_content_builder_document_path(saved))
  end
  it "rejects excess, stale, malformed, and invalid blocks transactionally" do
    create(:content_block, content_document: document)
    expect { described_class.call(document:, blocks: Array.new(13) { { type: "paragraph", body: "x" } }, expected_lock_version: 0) }.to raise_error(ArgumentError, /At most/)
    expect { described_class.call(document:, blocks: [ { type: "paragraph", body: "x" } ], expected_lock_version: 9) }.to raise_error(ActiveRecord::StaleObjectError)
    expect { described_class.call(document:, blocks: [ { type: "paragraph", body: "x", html: "<script>" } ], expected_lock_version: 0) }.to raise_error(ArgumentError, /Unknown/)
    expect { described_class.call(document:, blocks: [ { type: "video", body: "x" } ], expected_lock_version: 0) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(document.reload.content_blocks.count).to eq(1)
  end
  it "seeds idempotently" do
    admin = create(:admin_user)
    expect { ContentBuilder::Seed.call(admin_user: admin) }.to change(ContentBlock, :count).by(3)
    expect { ContentBuilder::Seed.call(admin_user: admin) }.not_to change(ContentBlock, :count)
  end
end
