# app/admin/activity_timeline.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Activity Timeline" do
  menu parent: "Collaboration", priority: 4

  controller do
    before_action :load_timeline_source

    private

    def load_timeline_source
      return unless params[:source].present?

      @timeline_source = Showcase::TimelineSources.new.find(id: params[:source], admin_user: current_admin_user)
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end

  content title: "Cross-Domain Activity Timeline" do
    para "Synthetic laboratory — seven domain-owned fixture families, not your live inbox or an audit log. Times are UTC. No writes occur here."
    if params[:source].present?
      source = assigns.fetch(:timeline_source)
      panel "#{Showcase::TimelineSources::FAMILIES.fetch(source.fetch(:family)).fetch(:label)} source" do
        h2 source.fetch(:title)
        para "Synthetic source #{source.fetch(:id)} · #{source.fetch(:actor)} · #{source.fetch(:occurred_at)}"
        dl do
          source.fetch(:fields).each { |label, value| dt(label); dd(value) }
        end
        para link_to("Back to timeline", admin_activity_timeline_path)
      end
    else
      query = params.permit(:actor, :cursor, :family, :group, :since).to_h
      result = begin
        Showcase::ActivityTimeline.new(admin_user: current_admin_user, params: query).page
      rescue ArgumentError => error
        div role: "alert" do
          para error.message
          para link_to("Start again", admin_activity_timeline_path)
        end
        nil
      end
      if result
        filters = result.fetch(:filters)
        panel "Filter history" do
          text_node form_with(url: admin_activity_timeline_path, method: :get) { |form|
            safe_join([
              form.label(:family, "Event family"),
              form.select(:family, [ [ "All families", "" ] ] + Showcase::TimelineSources::FAMILIES.map { |key, value| [ value.fetch(:label), key ] }, selected: filters.fetch("family")),
              form.label(:actor, "Actor"),
              form.select(:actor, [ [ "All actors", "" ] ] + (Showcase::TimelineSources::ACTORS + [ "Unavailable" ]).map { |actor| [ actor, actor ] }, selected: filters.fetch("actor")),
              form.label(:since, "On or after (UTC)"), form.date_field(:since, value: filters.fetch("since")),
              form.label(:group, "Group events by"), form.select(:group, [ [ "Day (UTC)", "day" ], [ "Event family", "family" ], [ "Actor", "actor" ] ], selected: filters.fetch("group")),
              form.submit("Apply timeline filters", class: "rounded border px-4 py-2")
            ])
          }
        end
        react_component "ActivityTimeline", props: result.merge(families: Showcase::TimelineSources::FAMILIES.transform_values { |definition| definition.fetch(:label) }), fallback: lambda {
          para "#{result.fetch(:items).size} events on this page; newest first within each group."
          if result.fetch(:items).empty?
            para "No events match these filters."
          end
          Showcase::ActivityTimeline.groups(result.fetch(:items), filters.fetch("group")).each do |label, items|
            h2 label
            ol do
              items.each do |event|
                li class: "mb-4 rounded border p-4" do
                  h3 event.fetch(:summary)
                  para do
                    text_node "#{event.fetch(:actor)} · "
                    time event.fetch(:occurredAt), datetime: event.fetch(:occurredAt)
                    text_node " · #{event.fetch(:family)}"
                  end
                  event.fetch(:details).each { |key, value| para "#{key}: #{value}" }
                  para link_to("Open source #{event.fetch(:id)}", event.fetch(:sourceUrl)) if event.fetch(:sourceUrl)
                end
              end
            end
          end
          para link_to("Older events", result.fetch(:nextUrl)) if result.fetch(:nextUrl)
          para link_to("Newest events", result.fetch(:startUrl))
        }
      end
    end
    para link_to("Timeline architecture and boundaries", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/activity-timeline.md")
  end
end
