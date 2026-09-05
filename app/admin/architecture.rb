# app/admin/architecture.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Architecture" do
  menu parent: "Overview", priority: 2

  content do
    panel "Dependency direction" do
      ul do
        li "activeadmin-react — small, generic OSS integration primitives"
        li "activeadmin-react-showcase — rich examples and reference integrations"
        li "Rodeo — enterprise consumer and dogfood environment"
      end
    end

    panel "Single-host foundation" do
      para "Rails owns authorization, persistence, jobs, cache, and Action Cable."
      para "SQLite, Solid Queue, Solid Cache, and Solid Cable keep the first deployment inexpensive and operationally coherent."
      para "The normalized Active Record boundary remains portable if measured load later justifies PostgreSQL."
    end
  end
end
