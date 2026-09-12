# app/services/spacecraft/serializer.rb
# frozen_string_literal: true

module Spacecraft
  class Serializer
    def initialize(model) = @model = model
    def as_json
      { assetUrl: "/models/odyssey.gltf", components: Catalog::COMPONENTS, finish: model.finish,
        finishes: SpacecraftModel::FINISHES, id: model.id.to_s, lockVersion: model.lock_version,
        name: model.name, selectedComponentId: model.selected_component_id,
        updateUrl: Rails.application.routes.url_helpers.admin_spacecraft_configuration_path(model) }
    end
    private
    attr_reader :model
  end
end
