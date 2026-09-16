# app/admin/hierarchy_explorer.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Hierarchy Explorer" do
  menu label: "Hierarchy Explorer", parent: "Data & Workflows", priority: 4

  content title: "Rails-authoritative Hierarchy Explorer" do
    roots = current_admin_user.hierarchy_nodes.roots.ordered

    panel "Demo" do
      para "Expand branches lazily, inspect breadcrumbs, use keyboard controls, or drag one node onto another. Rails owns validity, cycles, depth, ordering, and persistence."
    end

    react_component(
      "HierarchyExplorer",
      props: {
        roots: roots.map { |node| Hierarchy::Serializer.new(node).as_json }
      },
      fallback: lambda {
        render_branch = lambda do |nodes|
          content_tag(:ul) do
            safe_join(nodes.map do |node|
              content_tag(:li) do
                safe_join([
                  link_to(node.title, edit_admin_hierarchy_node_path(node)),
                  node.has_children? ? render_branch.call(node.children.ordered) : nil
                ].compact)
              end
            end)
          end
        end

        safe_join([
          content_tag(:p, "The complete authorized hierarchy remains navigable without JavaScript."),
          render_branch.call(roots)
        ])
      },
      class: "mt-6"
    )

    panel "Ruby" do
      para "Ancestry supplies generic tree navigation and cycle-safe reparenting. Hierarchy::Query and Hierarchy::Reparent retain owner scope, bounded reads, depth and sibling-order policy, and optimistic locks."
    end

    panel "JavaScript" do
      para "React owns expansion, selection, drag presentation, and rollback. Each node carries Rails-generated child and move URLs."
    end

    panel "Architecture" do
      para "Ancestry supplies portable materialized-path tree mechanics. Administrator ownership, authorization, lazy-load bounds, depth policy, sibling ordering, and rollback remain application responsibilities."
      para link_to("Read the hierarchy guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/hierarchy-explorer.md")
    end
  end
end
