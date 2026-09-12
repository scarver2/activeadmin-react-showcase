# app/admin/geospatial_explorer.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Geospatial Explorer" do
  menu label: "Geospatial Explorer", parent: "Data & Workflows", priority: 5

  content title: "Rails-authoritative Geospatial Explorer" do
    locations = ShowcaseLocation.order(:name)

    panel "Demo" do
      para "Pan, zoom, select clustered synthetic locations, and use the synchronized keyboard-accessible list."
    end

    react_component(
      "GeospatialExplorer",
      props: {
        endpoint: Rails.application.routes.url_helpers.admin_geospatial_locations_path,
        initialLocations: locations.map { |location| Geospatial::LocationSerializer.new(location).as_json }
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "The same authorized locations remain available without JavaScript."),
          content_tag(:table) do
            safe_join([
              content_tag(:thead, content_tag(:tr, safe_join(%w[Name Category Coordinates].map { |label| content_tag(:th, label) }))),
              content_tag(:tbody, safe_join(locations.map do |location|
                content_tag(:tr, safe_join([
                  content_tag(:td, link_to(location.name, admin_showcase_location_path(location))),
                  content_tag(:td, location.category),
                  content_tag(:td, "#{location.latitude}, #{location.longitude}")
                ]))
              end))
            ])
          end
        ])
      },
      class: "mt-6"
    )

    panel("Ruby", id: "ruby-guidance") { para "Geospatial::LocationQuery validates and caps bounding-box reads; Rails owns records and URLs." }
    panel("JavaScript", id: "javascript-guidance") { para "MapLibre renders a credential-free local scene while React synchronizes map and accessible list selection." }
    panel("Architecture", id: "architecture-guidance") { para "Spatial presentation stays showcase-local; normalized SQLite coordinates remain migration-friendly." }
  end
end
