# spec/lib/active_admin_themes_integration_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "active_admin/themes/recipe"

RSpec.describe "ActiveAdmin Themes integration" do
  it "keeps the committed V3 recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :v3,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(ActiveAdmin::Themes::VERSION).to eq("0.2.0.pre")
    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_v3.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::V3.source)
  end

  it "keeps the committed Texas Bluebonnet recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :texas_bluebonnet,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_texas_bluebonnet.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::TexasBluebonnet.source)
  end

  it "keeps the committed Workbench 1.3 recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :workbench_13,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_workbench_13.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::Workbench13.source)
  end

  it "keeps the committed Workbench 2.x recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :workbench_2,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_workbench_2.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::Workbench2.source)
  end

  it "keeps the committed Workbench 3.x recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :workbench_3,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_workbench_3.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::Workbench3.source)
  end

  it "keeps the committed MUI recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :mui,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_mui.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::Mui.source)
  end

  it "keeps the committed AmigaOS 4 recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :amigaos_4,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_amigaos_4.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::AmigaOS4.source)
  end

  it "keeps AmigaOS 4 presentation entirely gem-owned" do
    entrypoint = Rails.root.join("app/frontend/styles/active_admin.css").read

    expect(entrypoint).to include('@import "./active_admin_amigaos_4.css";')
    expect(entrypoint).not_to match(/--amigaos-4-[\w-]+:/)
    expect(entrypoint).not_to match(/\.amigaos-4-[\w-]+/)
  end

  it "keeps the Showcase MUI preference bounded to one token" do
    entrypoint = Rails.root.join("app/frontend/styles/active_admin.css").read

    expect(entrypoint).to include('body[data-activeadmin-theme="mui"] .mui-workspace[data-mui-preset="showcase-amethyst"]')
    expect(entrypoint).to include("--mui-active: #4f568d;")
    expect(entrypoint.scan(/--mui-[\w-]+:/)).to eq([ "--mui-active:" ])
  end
end
