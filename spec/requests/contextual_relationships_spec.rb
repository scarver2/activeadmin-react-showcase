# spec/requests/contextual_relationships_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contextual relationships" do
  it "requires authentication and provides canonical sources and native progressive context" do
    get admin_contextual_relationships_path
    expect(response).to redirect_to(new_admin_user_session_path)
    sign_in create(:admin_user)
    get admin_contextual_relationships_path
    expect(response.body).to include("Juniper Dispatch", "Avery Vale", "Relationship depth", 'data-react-component="ContextualRelationships"')
    get admin_contextual_relationships_path(depth: 3)
    expect(response.body).to include("packing-checklist.txt", "participates in")
    get admin_contextual_relationships_path(source: "file")
    expect(response.body).to include("File source", "Synthetic checklist metadata")
    %w[restricted deleted missing].each do |source|
      get admin_contextual_relationships_path(source:)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_empty
    end
    get admin_contextual_relationships_path(depth: 99)
    expect(response).to have_http_status(:bad_request)
  end
end
