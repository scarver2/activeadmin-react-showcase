# spec/helpers/showcase_icon_assets_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Showcase icon provenance" do
  let(:registry) { ShowcaseIconsHelper::ICON_REGISTRY }
  let(:sprite) { Nokogiri::XML(Rails.root.join("public/showcase-icons.svg").read).remove_namespaces! }

  it "ships exactly the registered functional glyphs and the original signature" do
    ids = sprite.css("symbol").map { |node| node["id"] }
    expect(ids).to match_array(registry.values.pluck("symbol").uniq + [ "landmark" ])
    expect(registry.values.pluck("library").uniq).to eq([ "heroicons" ])
  end

  it "preserves vendored Heroicons geometry and the upstream outline contract" do
    registry.each_value do |entry|
      source = Nokogiri::XML(Rails.root.join("vendor/icons/heroicons/24/outline/#{entry.fetch('glyph')}.svg").read)
        .remove_namespaces!
      symbol = sprite.at_css("symbol##{entry.fetch('symbol')}")
      expect(symbol["viewBox"]).to eq(source.root["viewBox"])
      expect(symbol.element_children.map(&:to_xml)).to eq(source.root.element_children.map(&:to_xml))
      expect(source.root["stroke-width"]).to eq("1.5")
      expect(source.root["stroke"]).to eq("currentColor")
      expect(source.root["fill"]).to eq("none")
    end
  end

  it "retains the MIT notice and forbids executable or remote sprite content" do
    expect(Rails.root.join("vendor/icons/heroicons/LICENSE").read).to include("MIT License", "Tailwind Labs")
    expect(sprite.css("script, foreignObject, image, use")).to be_empty
    expect(sprite.xpath("//@*[starts-with(name(), 'on')]")).to be_empty
  end

  it "reserves gear, tuning and hamburger semantics" do
    expect(registry.fetch("settings").fetch("glyph")).to eq("cog-6-tooth")
    expect(registry.fetch("filters").fetch("glyph")).to eq("adjustments-horizontal")
    expect(registry.fetch("navigation").fetch("glyph")).to eq("bars-3")
  end
end
