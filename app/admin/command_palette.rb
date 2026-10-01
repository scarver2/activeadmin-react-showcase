# app/admin/command_palette.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Command Palette" do
  menu label: "Command Palette", parent: "Developer Tools", priority: 1

  page_action :execute, method: :post do
    raise ActionController::BadRequest, "Explicit confirmation required" unless params[:confirmed] == "yes"

    destination = Showcase::PaletteCommands.new(admin_user: current_admin_user).execute(params[:command].to_s)
    redirect_to destination, notice: "Command completed."
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_command_palette_path, alert: "That command is no longer available. Search again."
  end

  content title: "Command Palette & Global Search" do
    query = params[:q].to_s
    search_error = nil
    results = begin
      recent = session[:palette_recent_owner] == current_admin_user.id ? session[:palette_recent] : []
      Showcase::PaletteSearch.new(admin_user: current_admin_user, query:, recent:).as_json.fetch(:results)
    rescue ArgumentError => error
      search_error = error.message
      []
    end

    if params[:command].present?
      panel "Confirm command" do
        begin
          command = Showcase::PaletteCommands.new(admin_user: current_admin_user).find(params[:command])
          para command.fetch(:label)
          para "This changes your operation or notification. Ownership and availability are checked again when you confirm."
          text_node form_with(url: admin_command_palette_execute_path, method: :post) { |form|
            safe_join([ form.hidden_field(:command, value: command.fetch(:id)),
                        form.hidden_field(:confirmed, value: "yes"), form.submit("Confirm command", class: "rounded border px-4 py-2 font-semibold") ])
          }
          para link_to("Cancel without changes", admin_command_palette_path)
        rescue ActiveRecord::RecordNotFound
          para "That command is no longer available. Search again.", role: "alert"
        end
      end
    end

    panel "Demo" do
      para "Use Search Showcase in the header or press Command-K / Control-K. Search workspace pages, Accounts and Showcase Articles without exposing database authority to the browser."
      para "Search without a term for recent context and permitted commands. Commands open a confirmation form; selecting a result never mutates a record."
      para link_to("Jump to Ruby", "#ruby-guidance") + " · " +
           link_to("Jump to JavaScript", "#javascript-guidance") + " · " +
           link_to("Jump to Architecture", "#architecture-guidance")
    end

    div class: "mt-6" do
      text_node safe_join([
          content_tag(:p, "Search remains available as an ordinary authenticated Rails form without JavaScript."),
          form_with(url: admin_command_palette_path, method: :get) do |form|
            safe_join([
              form.label(:q, "Search pages, accounts and articles"),
              form.search_field(:q, maxlength: Showcase::GlobalSearch::MAXIMUM_QUERY_LENGTH, value: query),
              form.submit("Search")
            ])
          end,
          if search_error
            content_tag(:p, search_error)
          elsif query.blank? && results.empty?
            content_tag(:p, "Enter a search term to find a navigable showcase record.")
          elsif results.empty?
            content_tag(:p, "No searchable records match “#{query}”.")
          else
            content_tag(:ul) do
              safe_join(results.map do |result|
                content_tag(:li, link_to("#{result.fetch(:kind)}: #{result.fetch(:label)}", result.fetch(:visitUrl, result.fetch(:url))))
              end)
            end
          end
      ])
    end

    panel "Ruby", id: "ruby-guidance" do
      para "Showcase::GlobalSearch requires an authenticated administrator, accepts at most 80 normalized characters, queries existing records, and returns only server-generated resource URLs."
      para "Exact matches rank before prefixes, prefixes before substrings, then resource kind, label, and record ID make ties deterministic."
    end

    panel "JavaScript", id: "javascript-guidance" do
      para "React owns the Command-K / Control-K shortcut, dialog focus, arrow-key selection, Enter navigation, Escape dismissal, and loading, empty, and error presentation."
      para "The component submits only text to the authenticated Rails endpoint and renders the returned navigation contract."
    end

    panel "Architecture", id: "architecture-guidance" do
      para "Global search is a bounded query service over the workspace catalogue, durable Accounts and Showcase Articles, not a SearchResult model or speculative index."
      para "The SQLite-compatible Active Record boundary remains migration-friendly; a dedicated search service is justified only after measured relevance or scale demands it."
      para link_to("Read the command palette guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/command-palette.md")
    end
  end
end
