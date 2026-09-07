# app/admin/file_image_manager.rb
# frozen_string_literal: true

ActiveAdmin.register_page "File Image Manager" do
  menu label: "File & Image Manager", parent: "Content", priority: 2

  content title: "File & Image Manager" do
    assets = ShowcaseAssets::Seed.call
    routes = Rails.application.routes.url_helpers

    panel "Safe local asset workflow" do
      para "Active Storage owns files on persistent Rails storage. Authenticated commands enforce allowlisted formats and a 5 MB limit."
    end

    react_component(
      "FileImageManager",
      props: {
        assets: assets.map { |asset| ShowcaseAssets::Serializer.new(asset).as_json },
        createUrl: routes.admin_showcase_assets_path,
        resetUrl: routes.admin_showcase_assets_reset_path
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "Assets remain downloadable and upload/delete/reset remain ordinary Rails forms without JavaScript."),
          content_tag(:ul) do
            safe_join(assets.map do |asset|
              content_tag(:li) do
                safe_join([
                  link_to(asset.title, rails_blob_path(asset.file, disposition: "inline")),
                  button_to("Delete", routes.admin_showcase_asset_path(asset), method: :delete)
                ], " ")
              end
            end)
          end,
          form_with(url: routes.admin_showcase_assets_path, method: :post, multipart: true) do |form|
            safe_join([
              form.label(:title, "Title"), form.text_field(:title, maxlength: 80, required: true),
              form.label(:file, "File"), form.file_field(:file, accept: ShowcaseAsset::ALLOWED_CONTENT_TYPES.join(","), required: true),
              form.submit("Upload asset")
            ])
          end,
          button_to("Reset synthetic assets", routes.admin_showcase_assets_reset_path, method: :post)
        ])
      },
      class: "mt-6"
    )
  end
end
