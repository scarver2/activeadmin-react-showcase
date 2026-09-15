# spec/requests/admin/material_sphere_configurations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin material sphere configurations" do
  let(:admin) { create(:admin_user) }
  let(:model) { create(:material_sphere, admin_user: admin) }

  before { sign_in admin }

  it "persists an allowlisted material recipe" do
    patch admin_material_sphere_configuration_path(model), params: { lock_version: 0, material_sphere: { finish: "ruby-metal" } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(model.reload).to have_attributes(finish: "ruby-metal", lock_version: 1)
  end

  it "rejects unsupported, stale, missing, and cross-owner values" do
    patch admin_material_sphere_configuration_path(model), params: { lock_version: 0, material_sphere: { finish: "blue" } }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_material_sphere_configuration_path(model), params: { lock_version: 99, material_sphere: { finish: "soft-red" } }, as: :json
    expect(response).to have_http_status(:conflict)
    patch admin_material_sphere_configuration_path(model), params: { lock_version: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_material_sphere_configuration_path(create(:material_sphere)), params: { lock_version: 0, material_sphere: { finish: "candy-red" } }, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "requires authentication" do
    sign_out admin
    patch admin_material_sphere_configuration_path(model), params: { lock_version: 0, material_sphere: { finish: "candy-red" } }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
