# app/admin/contextual_relationships.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Contextual Relationships" do
  menu parent: "Collaboration", priority: 3

  controller do
    before_action :load_relationships

    private

    def load_relationships
      explorer = Showcase::ContextualRelationships.new(admin_user: current_admin_user)
      @source = explorer.find(params[:source]) if params[:source].present?
      @graph = explorer.graph(root: params.fetch(:root, "customer"), depth: params.fetch(:depth, "1"))
    rescue ActiveRecord::RecordNotFound
      head :not_found
    rescue ArgumentError
      head :bad_request
    end
  end

  content title: "Contextual Relationship Explorer" do
    para "Synthetic laboratory — fictional customer, contact, order, project, work, conversation and file context. Read-only; Rails filters every relationship."
    if assigns[:source]
      source = assigns.fetch(:source)
      panel "#{source.fetch(:kind)} source" do
        h2 source.fetch(:name)
        para source.fetch(:detail)
        para link_to("Explore relationships from here", source.fetch(:exploreUrl))
      end
    else
      graph = assigns.fetch(:graph)
      panel "Bounded context" do
        para "Start with immediate neighbors. Expand deliberately, at most three steps, 24 records and 40 relationships."
        text_node form_with(url: admin_contextual_relationships_path, method: :get) { |form|
          safe_join([
            form.hidden_field(:root, value: graph.fetch(:rootId)),
            form.label(:depth, "Relationship depth"),
            form.select(:depth, [ [ "Immediate neighbors", 1 ], [ "Two steps", 2 ], [ "Three steps", 3 ] ], selected: graph.fetch(:depth)),
            form.submit("Expand context")
          ])
        }
      end
      react_component "ContextualRelationships", props: graph, fallback: lambda {
        h2 "Records"
        ul do
          graph.fetch(:nodes).each do |node|
            li do
              text_node "#{node.fetch(:kind)}: "
              text_node link_to(node.fetch(:name), node.fetch(:url))
              text_node " · "
              text_node link_to("Explore #{node.fetch(:name)}", node.fetch(:exploreUrl))
            end
          end
        end
        h2 "Relationships"
        ul do
          graph.fetch(:edges).each do |edge|
            names = graph.fetch(:nodes).index_by { |node| node.fetch(:id) }
            li "#{names.fetch(edge.fetch(:source)).fetch(:name)} → #{edge.fetch(:label)} → #{names.fetch(edge.fetch(:target)).fetch(:name)}"
          end
        end
      }
    end
    para link_to("Start at customer", admin_contextual_relationships_path)
  end
end
