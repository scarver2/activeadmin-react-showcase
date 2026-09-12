# spec/requests/admin/content_documents_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin content documents" do
  let(:admin) { create(:admin_user) }
  let(:document) { create(:content_document, admin_user: admin) }
  before { sign_in admin }

  it "updates an owned document" do
    patch admin_content_builder_document_path(document), params: { blocks: [ { type: "heading", body: "Launch" } ], lock_version: 0 }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("document", "blocks", 0, "body")).to eq("Launch")
  end
  it "rejects invalid and stale updates" do
    patch admin_content_builder_document_path(document), params: { blocks: [ { type: "unknown", body: "x" } ], lock_version: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_content_builder_document_path(document), params: { blocks: [ { type: "paragraph", body: "stale" } ], lock_version: 99 }, as: :json
    expect(response).to have_http_status(:conflict)
  end
  it "rejects missing blocks, other owners, and anonymous requests" do
    patch admin_content_builder_document_path(document), params: { lock_version: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    other = create(:content_document)
    patch admin_content_builder_document_path(other), params: { blocks: [], lock_version: 0 }, as: :json
    expect(response).to have_http_status(:not_found)
    sign_out admin
    patch admin_content_builder_document_path(document), params: { blocks: [], lock_version: 0 }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
