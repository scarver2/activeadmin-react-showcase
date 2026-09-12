# spec/requests/admin/geospatial_locations_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin geospatial locations" do
  let(:admin) { create(:admin_user) }
  before { sign_in admin }

  it "returns a bounded projection" do
    create(:showcase_location)
    get admin_geospatial_locations_path, params: { bounds: "-100,28,-95,32" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("locations").length).to eq(1)
  end

  it "returns a useful malformed-bounds response" do
    get admin_geospatial_locations_path, params: { bounds: "world" }
    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.fetch("error")).to include("Bounds")
  end

  it "requires authentication" do
    sign_out admin
    get admin_geospatial_locations_path, params: { bounds: "-100,28,-95,32" }
    expect(response).to have_http_status(:unauthorized)
  end
end
