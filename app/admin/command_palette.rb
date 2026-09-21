# app/admin/command_palette.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Command Palette" do
  menu label: "Command Palette", parent: "Developer Tools", priority: 1

  content title: "Command Palette & Global Search" do
    query = params[:q].to_s
    search_error = nil
    results = begin
      Showcase::GlobalSearch.new(admin_user: current_admin_user, query:).as_json.fetch(:results)
    rescue ArgumentError => error
      search_error = error.message
      []
    end

    panel "Demo" do
      para "Open the palette or press Command-K / Control-K. Search navigable Accounts and Showcase Articles without exposing database authority to the browser."
      para link_to("Jump to Ruby", "#ruby-guidance") + " · " +
           link_to("Jump to JavaScript", "#javascript-guidance") + " · " +
           link_to("Jump to Architecture", "#architecture-guidance")
    end

    react_component(
      "CommandPalette",
      props: {
        endpoint: Rails.application.routes.url_helpers.admin_global_search_path,
        initialQuery: search_error ? "" : query
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "Search remains available as an ordinary authenticated Rails form without JavaScript."),
          form_with(url: admin_command_palette_path, method: :get) do |form|
            safe_join([
              form.label(:q, "Search accounts and articles"),
              form.search_field(:q, maxlength: Showcase::GlobalSearch::MAXIMUM_QUERY_LENGTH, value: query),
              form.submit("Search")
            ])
          end,
          if search_error
            content_tag(:p, search_error)
          elsif query.blank?
            content_tag(:p, "Enter a search term to find a navigable showcase record.")
          elsif results.empty?
            content_tag(:p, "No searchable records match “#{query}”.")
          else
            content_tag(:ul) do
              safe_join(results.map do |result|
                content_tag(:li, link_to("#{result.fetch(:kind)}: #{result.fetch(:label)}", result.fetch(:url)))
              end)
            end
          end
        ])
      },
      class: "mt-6"
    )

    panel "Ruby", id: "ruby-guidance" do
      para "Showcase::GlobalSearch requires an authenticated administrator, accepts at most 80 normalized characters, queries existing records, and returns only server-generated resource URLs."
      para "Exact matches rank before prefixes, prefixes before substrings, then resource kind, label, and record ID make ties deterministic."
    end

    panel "JavaScript", id: "javascript-guidance" do
      para "React owns the Command-K / Control-K shortcut, dialog focus, arrow-key selection, Enter navigation, Escape dismissal, and loading, empty, and error presentation."
      para "The component submits only text to the authenticated Rails endpoint and renders the returned navigation contract."
    end

    panel "Architecture", id: "architecture-guidance" do
      para "Global search is a bounded query service over durable Accounts and Showcase Articles, not a SearchResult model or speculative index."
      para "The SQLite-compatible Active Record boundary remains migration-friendly; a dedicated search service is justified only after measured relevance or scale demands it."
      para link_to("Read the command palette guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/command-palette.md")
    end
  end
end
