# spec/requests/admin/social_graph_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin social graph" do
  let(:admin) { create(:admin_user) }
  let!(:people) { SocialGraph::Seed.call(admin_user: admin) }
  before { sign_in admin }
  it "returns an authorized bounded graph" do
    get admin_social_graph_path, params: { root_id: people.first.id, target_id: people.second.id, depth: 2 }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("nodes")).not_to be_empty
  end
  it "rejects invalid depth and cross-owner roots" do
    get admin_social_graph_path, params: { root_id: people.first.id, depth: 9 }
    expect(response).to have_http_status(:bad_request)
    other = create(:social_person)
    get admin_social_graph_path, params: { root_id: other.id }
    expect(response).to have_http_status(:not_found)
  end
  it "requires authentication" do
    sign_out admin
    get admin_social_graph_path, params: { root_id: people.first.id }
    expect(response).to have_http_status(:unauthorized)
  end
end
