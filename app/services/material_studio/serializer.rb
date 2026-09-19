# app/services/material_studio/serializer.rb
# frozen_string_literal: true

module MaterialStudio
  class Serializer
    def initialize(model) = @model = model

    def as_json
      { finish: model.finish, finishes: Catalog::FINISHES, id: model.id.to_s,
        lockVersion: model.lock_version, name: model.name,
        updateUrl: Rails.application.routes.url_helpers.admin_material_sphere_configuration_path(model) }
    end

    private

    attr_reader :model
  end
end
