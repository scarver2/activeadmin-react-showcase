# spec/services/material_studio_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaterialStudio::Serializer do
  it "publishes only allowlisted material recipes and the Rails endpoint" do
    model = create(:material_sphere)
    payload = described_class.new(model).as_json
    expect(payload).to include(finish: "candy-red", updateUrl: Rails.application.routes.url_helpers.admin_material_sphere_configuration_path(model))
    expect(payload[:finishes].pluck(:id)).to eq(MaterialStudio::Catalog.ids)
    expect(payload).not_to have_key(:assetUrl)
  end

  it "seeds idempotently" do
    admin = create(:admin_user)
    expect { MaterialStudio::Seed.call(admin_user: admin) }.to change(MaterialSphere, :count).by(1)
    expect { MaterialStudio::Seed.call(admin_user: admin) }.not_to change(MaterialSphere, :count)
  end
end
