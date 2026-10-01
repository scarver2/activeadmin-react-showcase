# spec/requests/calm_attention_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calm attention dashboard" do
  it "renders useful native controls and clearly labeled synthetic and healthy states" do
    get admin_calm_attention_path
    expect(response).to redirect_to(new_admin_user_session_path)
    sign_in create(:admin_user)
    get admin_calm_attention_path(scenario: "exceptions")
    expect(response.body).to include("Synthetic demonstration only", "Urgent", "Needs action", "For awareness", "Supporting context")
    expect(response.body).to include("<details", "<summary")
    get admin_calm_attention_path(scenario: "healthy")
    expect(response.body).to include("All clear", "Nothing needs attention")
    get admin_calm_attention_path(scenario: "untrusted")
    expect(response.body).to include("Live owner-scoped inbox")
  end
end
