# spec/requests/active_storage/conversation_attachment_boundary_spec.rb
# frozen_string_literal: true

require "base64"
require "rails_helper"

RSpec.describe "Conversation attachment Active Storage boundary" do
  let(:admin) { create(:admin_user) }
  let(:conversation) { create(:conversation, public_id: "private-files") }
  let(:membership) { create(:conversation_membership, admin_user: admin, conversation:) }

  it "rejects permanent blob and proxy capabilities for unauthenticated and outsider requests before and after withdrawal" do
    message = create_message_with_attachment
    attachment = message.attachment
    blob_path = rails_blob_path(attachment.file, only_path: true)
    proxy_path = rails_storage_proxy_path(attachment.file, only_path: true)

    get blob_path
    expect(response).to have_http_status(:not_found)
    get proxy_path
    expect(response).to have_http_status(:not_found)

    outsider = create(:admin_user)
    sign_in outsider
    get blob_path
    expect(response).to have_http_status(:not_found)

    Conversations::WithdrawMessage.call(message:, membership:)
    get blob_path
    expect(response).to have_http_status(:not_found)
    sign_out :admin_user
    get blob_path
    expect(response).to have_http_status(:not_found)
    get proxy_path
    expect(response).to have_http_status(:not_found)
  end

  it "rejects permanent representation capabilities before image processing" do
    message = create_message_with_attachment(upload: image_upload)
    variant = message.attachment.file.variant(resize_to_limit: [ 1, 1 ])
    representation_path = rails_representation_path(variant, only_path: true)
    representation_proxy_path = rails_storage_proxy_path(variant, only_path: true)

    get representation_path
    expect(response).to have_http_status(:not_found)
    get representation_proxy_path

    expect(response).to have_http_status(:not_found)
    expect(ActiveStorage::VariantRecord.count).to eq(0)
  ensure
    @image_tempfile&.close!
  end

  it "preserves the existing public signed route behavior for unrelated Showcase assets" do
    asset = create(:showcase_asset)

    get rails_blob_path(asset.file, only_path: true)

    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/rails/active_storage/disk/")
  end

  private

  def create_message_with_attachment(upload: fixture_file_upload("sample.txt", "text/plain"))
    Conversations::CreateMessage.call(
      attachment: upload,
      body: "Membership-scoped file",
      conversation:,
      membership:
    )
  end

  def image_upload
    @image_tempfile = Tempfile.new([ "proof", ".png" ])
    @image_tempfile.binmode
    @image_tempfile.write(Base64.strict_decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WlYv1sAAAAASUVORK5CYII="
    ))
    @image_tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(
      filename: "proof.png",
      tempfile: @image_tempfile,
      type: "image/png"
    )
  end
end
