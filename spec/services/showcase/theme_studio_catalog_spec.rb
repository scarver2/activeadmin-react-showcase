# spec/services/showcase/theme_studio_catalog_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Showcase::ThemeStudioCatalog do
  subject(:catalog) { described_class.new.as_json }

  it "projects the actual installed theme, skin, composition and manifest contract" do
    architecture = catalog.fetch(:architecture)

    expect(architecture).to include(
      recipeVersion: "2",
      theme: { key: :v3, name: "ActiveAdmin V3" }
    )
    expect(architecture.fetch(:skin)).to include(key: :v3, parts: [ "foundation/tokens" ])
    expect(architecture.fetch(:composition).fetch(:parts)).to eq(
      ActiveAdmin::Themes::Recipes::V3::COMPOSITION_PARTS
    )
  end

  it "derives light and dark semantic values from the installed skin source" do
    colors = catalog.fetch(:colors).index_by { |token| token.fetch(:key) }

    expect(colors.fetch(:background)).to include(light: "#f3f4f5", dark: "#171c21")
    expect(colors.fetch(:focus)).to include(light: "#175eac", dark: "#f3cf79")
    expect(colors.keys).to include(:danger, :success, :warning)
  end

  it "exposes only bounded geometry variables already declared by the recipe" do
    geometry = catalog.fetch(:geometry).index_by { |token| token.fetch(:key) }

    expect(geometry).to match(
      border_width: include(value: "1px"),
      control_height: include(value: "2.25rem"),
      page_gutter: include(value: "1.875rem"),
      radius: include(value: "0.25rem")
    )
    expect(catalog.fetch(:typography).index_by { |token| token.fetch(:key) }).to match(
      font: include(value: include("BlinkMacSystemFont")),
      line_height: include(value: "1.5"),
      text_size: include(value: "0.875rem")
    )
  end
end
