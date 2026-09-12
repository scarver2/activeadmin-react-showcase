# spec/services/spacecraft_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spacecraft::Serializer do
  it "publishes only the local asset, allowlists, metadata, and Rails endpoint" do
    model = create(:spacecraft_model)
    payload = described_class.new(model).as_json
    expect(payload).to include(assetUrl: "/models/odyssey.gltf", finishes: %w[ceramic titanium], updateUrl: Rails.application.routes.url_helpers.admin_spacecraft_configuration_path(model))
    expect(payload[:components].map { |component| component[:id] }).to eq(Spacecraft::Catalog.ids)
  end
  it "seeds idempotently" do
    admin = create(:admin_user)
    expect { Spacecraft::Seed.call(admin_user: admin) }.to change(SpacecraftModel, :count).by(1)
    expect { Spacecraft::Seed.call(admin_user: admin) }.not_to change(SpacecraftModel, :count)
  end
end
