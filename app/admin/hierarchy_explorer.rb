# app/admin/hierarchy_explorer.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Hierarchy Explorer" do
  menu label: "Hierarchy Explorer", parent: "Data & Workflows", priority: 4

  content title: "Rails-authoritative Hierarchy Explorer" do
    roots = current_admin_user.hierarchy_nodes.roots

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
                  node.children.any? ? render_branch.call(node.children) : nil
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
      para "Hierarchy::Query bounds lazy child reads. Hierarchy::Reparent validates ownership, cycles, depth, ordering, and optimistic lock versions before persistence."
    end

    panel "JavaScript" do
      para "React owns expansion, selection, drag presentation, and rollback. Each node carries Rails-generated child and move URLs."
    end

    panel "Architecture" do
      para "A portable adjacency list keeps application hierarchy semantics in Rails and SQLite. The showcase deliberately avoids a generic tree framework."
      para link_to("Read the hierarchy guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/hierarchy-explorer.md")
    end
  end
end
