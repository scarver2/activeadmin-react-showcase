# app/admin/bulk_action_workbench.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Bulk Action Workbench" do
  menu parent: "Data & Workflows", priority: 9

  page_action :preview, method: :post do
    batch = Showcase::BulkRegions.preview(admin_user: current_admin_user, ids: params[:account_ids], region: params[:region])
    redirect_to admin_bulk_action_workbench_path(batch: batch.id)
  rescue Showcase::BulkRegions::Rejected => error
    redirect_to admin_bulk_action_workbench_path, alert: error.message
  end

  page_action :confirm, method: :post do
    raise ActionController::BadRequest unless params[:confirmed] == "yes"

    batch = Showcase::BulkRegions.confirm(admin_user: current_admin_user, id: params[:batch_id])
    redirect_to admin_bulk_action_workbench_path(batch: batch.id), notice: "Confirmed. Durable processing can be resumed without replaying completed records."
  end

  page_action :status, method: :get do
    batch = BulkRegionBatch.where(admin_user: current_admin_user).find(params[:batch_id])
    render json: { state: batch.state, progress: batch.progress, results: batch.results }
  end

  content title: "Bulk Action Workbench" do
    panel "Demo" do
      para "Select up to 25 synthetic accounts. Preview changing their region, explicitly confirm, then observe durable per-record outcomes. Rails checks each record again at execution."
    end
    if params[:batch]
      batch = BulkRegionBatch.where(admin_user: current_admin_user).find(params[:batch])
      panel "Preview and results" do
        para "Target region: #{batch.region}. Batch #{batch.id}."
        react_component("BulkProgress", props: {
          endpoint: admin_bulk_action_workbench_status_path(batch_id: batch.id),
          initial: { state: batch.state, progress: batch.progress, results: batch.results }
        }, fallback: -> { content_tag(:p, "#{batch.state.capitalize}: #{batch.progress}%") })
        table class: "w-full text-left" do
          thead do
            tr do
              th "Account", class: "px-3 py-2"
              th "Preview", class: "px-3 py-2"
              th "Outcome", class: "px-3 py-2"
            end
          end
          tbody do
            batch.selection.each do |item|
              tr do
                td item.fetch("name"), class: "px-3 py-2"
                td item.fetch("reason"), class: "px-3 py-2"
                td batch.results.fetch(item.fetch("id").to_s, "pending"), class: "px-3 py-2"
              end
            end
          end
        end
        unless batch.state == "completed"
          text_node button_to(batch.state == "preview" ? "Confirm region changes" : "Resume pending records",
            admin_bulk_action_workbench_confirm_path, method: :post, params: { batch_id: batch.id, confirmed: "yes" }, class: "rounded border px-4 py-2")
        end
        para link_to("Refresh canonical results", admin_bulk_action_workbench_path(batch: batch.id))
        para link_to("Start a new preview", admin_bulk_action_workbench_path)
      end
    else
      panel "Select accounts" do
        text_node form_with(url: admin_bulk_action_workbench_preview_path, method: :post) { |form|
          rows = Account.order(:name).limit(25).map do |account|
            content_tag(:tr, safe_join([
              content_tag(:td, check_box_tag("account_ids[]", account.id, false, id: "select_account_#{account.id}"), class: "px-3 py-2"),
              content_tag(:td, label_tag("select_account_#{account.id}", account.name), class: "px-3 py-2"),
              content_tag(:td, account.region, class: "px-3 py-2"), content_tag(:td, account.status, class: "px-3 py-2")
            ]))
          end
          safe_join([ form.label(:region, "Target region"), form.select(:region, Account::REGIONS),
            content_tag(:table, safe_join([
              content_tag(:thead, content_tag(:tr, safe_join(%w[Select Account Region Status].map { |label| content_tag(:th, label, class: "px-3 py-2") }))),
              content_tag(:tbody, safe_join(rows))
            ]), class: "w-full text-left"), form.submit("Preview selected records", class: "rounded border px-4 py-2") ])
        }
      end
      panel "Your recent batches" do
        BulkRegionBatch.where(admin_user: current_admin_user).order(id: :desc).limit(10).each do |batch|
          para link_to("Batch #{batch.id}: #{batch.state}, #{batch.progress}%", admin_bulk_action_workbench_path(batch: batch.id))
        end
      end
    end
    panel "Implementation" do
      para "Solid Queue processes a persisted selection. Each record's mutation and result commit together. Duplicate jobs skip durable results; conflict or permission changes never overwrite a newer record."
      para link_to("Read the bulk workbench contract", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/bulk-workbench.md")
    end
  end
end
