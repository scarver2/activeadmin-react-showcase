# app/admin/theme_studio.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Theme Studio" do
  menu label: "Theme Studio", parent: "Developer Tools", priority: 2

  content title: "Semantic Theme Studio" do
    catalog = Showcase::ThemeStudioCatalog.new.as_json

    panel "Laboratory boundary" do
      para <<~TEXT.squish
        Edit a bounded projection of the installed activeadmin-themes 0.2.0 V3 skin while its
        composition remains explicit and immutable. This prototype neither persists preferences
        nor injects arbitrary CSS.
      TEXT
    end

    react_component(
      "ThemeStudio",
      props: catalog,
      fallback: lambda {
        architecture = catalog.fetch(:architecture)
        safe_join([
          content_tag(:h2, "#{architecture.dig(:theme, :name)} baseline"),
          content_tag(:p, "JavaScript is optional: the canonical recipe contract remains inspectable."),
          content_tag(:dl, safe_join([
            content_tag(:dt, "Skin"), content_tag(:dd, architecture.dig(:skin, :name)),
            content_tag(:dt, "Composition"), content_tag(:dd, architecture.dig(:composition, :name)),
            content_tag(:dt, "Recipe version"), content_tag(:dd, architecture.fetch(:recipeVersion))
          ])),
          content_tag(:p, "Use the installed deterministic recipe as the source of truth; interactive edits are reversible preview state only.")
        ])
      },
      class: "mt-6"
    )
  end
end
