# spec/requests/admin/operator_chat_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin operator chat" do
  let(:room) { OperatorChat::Seed.call }

  it "requires an authenticated administrator" do
    post admin_operator_chat_messages_path(room.public_id), params: { body: "No access" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "creates a message without trusting a browser-supplied author" do
    sign_in create(:admin_user)
    post admin_operator_chat_messages_path(room.public_id),
         params: { body: "Approved.", author_key: "maya", author_name: "Spoofed" }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include("authorKey" => "operator", "authorName" => "You", "body" => "Approved.")
  end

  it "returns validation errors and supports the HTML fallback" do
    sign_in create(:admin_user)
    post admin_operator_chat_messages_path(room.public_id), params: { body: "" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)

    post admin_operator_chat_messages_path(room.public_id), params: { body: "From fallback" }
    expect(response).to redirect_to(admin_operator_chat_path)
  end

  it "resets only through an authenticated command" do
    sign_in create(:admin_user)
    OperatorChat::PostMessage.call(room:, body: "Temporary")

    post admin_operator_chat_reset_path(room.public_id), as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("authorKey")).to eq(%w[maya jordan])
  end
end
