# app/services/material_studio/catalog.rb
# frozen_string_literal: true

module MaterialStudio
  class Catalog
    FINISHES = [
      { id: "candy-red", label: "Candy red", color: "#d20a2e", roughness: 0.08, metalness: 0.12, clearcoat: 1.0 },
      { id: "ruby-metal", label: "Ruby metal", color: "#b5082d", roughness: 0.14, metalness: 0.72, clearcoat: 0.9 },
      { id: "soft-red", label: "Soft red", color: "#e11d48", roughness: 0.32, metalness: 0.0, clearcoat: 0.65 }
    ].freeze

    def self.ids = FINISHES.map { |finish| finish.fetch(:id) }
  end
end
