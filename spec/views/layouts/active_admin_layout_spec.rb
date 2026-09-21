# spec/views/layouts/active_admin_layout_spec.rb
# frozen_string_literal: true

require "digest"
require "rails_helper"

RSpec.describe "ActiveAdmin layout override" do
  it "matches ActiveAdmin beta22 apart from the server-rendered theme opt-in" do
    upstream = Pathname.new(Gem.loaded_specs.fetch("activeadmin").full_gem_path)
      .join("app/views/layouts/active_admin.html.erb")
    override = Rails.root.join("app/views/layouts/active_admin.html.erb").read

    expect(Digest::SHA256.file(upstream).hexdigest)
      .to eq("97c8e7f31edfa37ec80705fec9676f2621e93762c3cdc4999a687b1639d973c0")

    normalized = override.lines.drop(3)
      .reject { |line| line.start_with?("<% bluebonnet_theme =") }
      .join
      .sub(
        /<body class="bg-white dark:bg-gray-950\/95 text-gray-950 dark:text-gray-100 antialiased".*>/,
        '<body class="bg-white dark:bg-gray-950/95 text-gray-950 dark:text-gray-100 antialiased">'
      )

    expect(normalized).to eq(upstream.read)
  end
end
