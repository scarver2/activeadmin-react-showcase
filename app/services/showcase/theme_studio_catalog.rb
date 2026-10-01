# app/services/showcase/theme_studio_catalog.rb
# frozen_string_literal: true

module Showcase
  # Projects the immutable activeadmin-themes contract into a bounded editor schema.
  class ThemeStudioCatalog
    THEME_KEY = :v3
    COLOR_TOKENS = {
      background: "Canvas",
      border: "Border",
      chrome: "Chrome",
      chrome_text: "Chrome text",
      danger: "Danger text",
      danger_bg: "Danger surface",
      focus: "Focus",
      link: "Link / accent",
      muted: "Muted text",
      selected: "Selection",
      subtle: "Subtle surface",
      success: "Success text",
      success_bg: "Success surface",
      surface: "Surface",
      text: "Text",
      warning: "Warning text",
      warning_bg: "Warning surface"
    }.freeze
    GEOMETRY_TOKENS = {
      border_width: "Border weight",
      control_height: "Control height",
      page_gutter: "Page gutter",
      radius: "Radius"
    }.freeze
    TYPOGRAPHY_TOKENS = {
      font: "Font family",
      line_height: "Line height",
      text_size: "Base text size"
    }.freeze

    def as_json(*)
      {
        architecture: architecture,
        colors: colors,
        geometry: geometry,
        typography: typography
      }
    end

    private

    def architecture
      {
        activeAdminRequirement: theme.active_admin_requirement.to_s,
        composition: {
          description: theme.composition.description,
          key: theme.composition.key,
          name: theme.composition.name,
          parts: ActiveAdmin::Themes::Recipes::V3::COMPOSITION_PARTS,
          slots: theme.composition.slots
        },
        recipeVersion: theme.recipe_version,
        skin: {
          description: theme.skin.description,
          key: theme.skin.key,
          name: theme.skin.name,
          parts: ActiveAdmin::Themes::Recipes::V3::SKIN_PARTS
        },
        theme: { key: theme.key, name: theme.name }
      }
    end

    def colors
      COLOR_TOKENS.map do |key, label|
        {
          key: key,
          label: label,
          light: token_values.fetch("--aat-#{key.to_s.tr("_", "-")}"),
          dark: dark_token_values.fetch("--aat-#{key.to_s.tr("_", "-")}")
        }
      end
    end

    def geometry
      GEOMETRY_TOKENS.map do |key, label|
        variable = "--aat-#{key.to_s.tr("_", "-")}"
        { key: key, label: label, value: token_values.fetch(variable) }
      end
    end

    def typography
      TYPOGRAPHY_TOKENS.map do |key, label|
        variable = "--aat-#{key.to_s.tr("_", "-")}"
        { key: key, label: label, value: token_values.fetch(variable) }
      end
    end

    def declarations(source)
      source.scan(/(--aat-[\w-]+):\s*([^;]+);/).to_h.freeze
    end

    def token_values
      @token_values ||= declarations(theme.skin.source.split("html.dark", 2).first)
    end

    def dark_token_values
      @dark_token_values ||= token_values.merge(declarations(theme.skin.source.split("html.dark", 2).last))
    end

    def theme
      @theme ||= ActiveAdmin::Themes.registry.fetch(THEME_KEY)
    end
  end
end
