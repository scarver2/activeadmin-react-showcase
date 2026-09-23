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

  it "keeps the committed AROS Zune recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :aros_zune,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_aros_zune.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::AROSZune.source)
  end

  it "keeps AROS Zune presentation entirely gem-owned" do
    entrypoint = Rails.root.join("app/frontend/styles/active_admin.css").read

    expect(entrypoint).to include('@import "./active_admin_aros_zune.css";')
    expect(entrypoint).not_to match(/--aros-zune-[\w-]+:/)
    expect(entrypoint).not_to match(/\.aros-zune-[\w-]+/)
  end

  it "keeps the committed Haiku beta6 recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :haiku_beta6,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_haiku_beta6.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::HaikuBeta6.source)
  end

  it "keeps Haiku beta6 presentation entirely gem-owned" do
    entrypoint = Rails.root.join("app/frontend/styles/active_admin.css").read

    expect(entrypoint).to include('@import "./active_admin_haiku_beta6.css";')
    expect(entrypoint).not_to match(/--haiku-beta6-[\w-]+:/)
    expect(entrypoint).not_to match(/\.haiku-beta6-[\w-]+/)
  end

  it "keeps the committed Video Toaster 4000 recipe identical to the pinned gem source" do
    recipe = ActiveAdmin::Themes::Recipe.new(
      root: Rails.root.to_s,
      entrypoint: "app/frontend/styles/active_admin.css",
      key: :video_toaster_4000,
      active_admin_version: ActiveAdmin::VERSION
    )

    expect(recipe.status).to eq(:identical)
    expect(Rails.root.join("app/frontend/styles/active_admin_video_toaster_4000.css").binread)
      .to eq(ActiveAdmin::Themes::Recipes::VideoToaster4000.source)
  end

  it "keeps Video Toaster 4000 presentation entirely gem-owned" do
    entrypoint = Rails.root.join("app/frontend/styles/active_admin.css").read

    expect(entrypoint).to include('@import "./active_admin_video_toaster_4000.css";')
    expect(entrypoint).not_to match(/--video-toaster-4000-[\w-]+:/)
    expect(entrypoint).not_to match(/\.video-toaster-4000-[\w-]+/)
  end

  it "keeps the Showcase MUI preference bounded to one token" do
    entrypoint = Rails.root.join("app/frontend/styles/active_admin.css").read

    expect(entrypoint).to include('body[data-activeadmin-theme="mui"] .mui-workspace[data-mui-preset="showcase-amethyst"]')
    expect(entrypoint).to include("--mui-active: #4f568d;")
    expect(entrypoint.scan(/--mui-[\w-]+:/)).to eq([ "--mui-active:" ])
  end
end
