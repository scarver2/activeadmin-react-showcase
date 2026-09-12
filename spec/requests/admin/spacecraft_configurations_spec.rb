# spec/requests/admin/spacecraft_configurations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin spacecraft configurations" do
  let(:admin) { create(:admin_user) }
  let(:model) { create(:spacecraft_model, admin_user: admin) }
  before { sign_in admin }
  it "persists allowlisted configuration" do
    patch admin_spacecraft_configuration_path(model), params: { lock_version: 0, spacecraft: { finish: "ceramic", selected_component_id: "port-wing" } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(model.reload).to have_attributes(finish: "ceramic", selected_component_id: "port-wing")
  end
  it "rejects unsupported, stale, missing, and cross-owner values" do
    patch admin_spacecraft_configuration_path(model), params: { lock_version: 0, spacecraft: { finish: "gold", selected_component_id: "hatch" } }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_spacecraft_configuration_path(model), params: { lock_version: 99, spacecraft: { finish: "titanium" } }, as: :json
    expect(response).to have_http_status(:conflict)
    patch admin_spacecraft_configuration_path(model), params: { lock_version: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_spacecraft_configuration_path(create(:spacecraft_model)), params: { lock_version: 0, spacecraft: { finish: "titanium" } }, as: :json
    expect(response).to have_http_status(:not_found)
  end
  it "requires authentication" do
    sign_out admin
    patch admin_spacecraft_configuration_path(model), params: { lock_version: 0, spacecraft: { finish: "titanium" } }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
