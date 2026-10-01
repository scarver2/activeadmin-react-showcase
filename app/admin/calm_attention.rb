# app/admin/calm_attention.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Calm Attention" do
  menu parent: "Dashboards", priority: 4

  content title: "Calm operations attention" do
    scenario = Showcase::CalmAttention::SCENARIOS.include?(params[:scenario]) ? params[:scenario] : "live"
    groups = Showcase::CalmAttention.new(admin_user: current_admin_user, scenario:).groups
    panel "Demo" do
      para "Exceptions earn attention. Routine work recedes. Rails owns the inputs; there is no AI score or automatic action."
      text_node form_with(url: admin_calm_attention_path, method: :get) { |form|
        safe_join([ form.label(:scenario, "Attention scenario"), form.select(:scenario, [ [ "Your live inbox", "live" ], [ "Synthetic exceptions", "exceptions" ], [ "Synthetic healthy state", "healthy" ] ], selected: scenario), form.submit("Show scenario", class: "rounded border px-4 py-2") ])
      }
      para(scenario == "live" ? "Live owner-scoped inbox; dismissed and snoozed notifications are excluded." : "Synthetic demonstration only — this does not change or summarize your live inbox.")
    end
    if groups.all? { |group| group.fetch(:items).empty? }
      panel "All clear" do
        para "Nothing needs attention in this view. Healthy work is a success state, not missing content."
        para link_to("Open activity center", admin_activity_center_path)
      end
    else
      groups.each do |group|
        next if group.fetch(:items).empty?

        content = lambda do
          ul do
            group.fetch(:items).each do |item|
              li class: "mb-4 rounded border p-4" do
                h3 item.fetch(:title)
                para item.fetch(:reason)
                para link_to(item.fetch(:action), item.fetch(:url), class: "underline")
                details do
                  summary "Supporting context"
                  para item.fetch(:context)
                end
              end
            end
          end
          para "#{group.fetch(:remaining)} more in the activity center." if group.fetch(:remaining).positive?
        end
        if group.fetch(:key) == "fyi"
          details class: "rounded border p-4" do
            summary group.fetch(:label)
            content.call
          end
        else
          panel(group.fetch(:label)) { content.call }
        end
      end
    end
    para link_to("How attention is prioritized", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/calm-attention.md")
  end
end
