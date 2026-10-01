# app/admin/reversible_actions.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Reversible Actions" do
  menu parent: "Data & Workflows", priority: 8

  page_action :change, method: :post do
    receipt = Showcase::ReversibleRegions.change(admin_user: current_admin_user,
      account: Account.find(params[:account_id]), value: params[:region], request_key: params[:request_key], expected_version: params[:lock_version])
    redirect_to admin_reversible_actions_path(receipt: receipt.id, anchor: "receipts"), notice: "Region changed. Undo is available for 30 seconds."
  rescue Showcase::ReversibleRegions::Rejected => error
    redirect_to admin_reversible_actions_path, alert: error.message
  end

  page_action :undo, method: :post do
    receipt = Showcase::ReversibleRegions.undo(admin_user: current_admin_user, id: params[:receipt_id])
    redirect_to admin_reversible_actions_path(receipt: receipt.id, anchor: "receipts"), notice: "Undo recorded. The original region is restored."
  rescue Showcase::ReversibleRegions::Rejected => error
    redirect_to admin_reversible_actions_path, alert: error.message
  end

  content title: "Audited Reversible Actions" do
    panel "Demo" do
      para "Change the region of an active synthetic account, then undo within 30 seconds. Rails owns time, authorization, concurrent-change checks and the audit trail."
      para "Reload to see current eligibility. An expired or conflicted action is not silently overwritten; use the canonical account page to inspect it."
    end
    panel "Change a region" do
      Account.order(:name).limit(10).each do |account|
        next unless InlineEditing::Policy.new(admin_user: current_admin_user, account:).permitted?("region")

        div do
          para link_to(account.name, admin_account_path(account))
          text_node form_with(url: admin_reversible_actions_change_path, method: :post) { |form|
            safe_join([ form.hidden_field(:account_id, value: account.id),
              form.hidden_field(:lock_version, value: account.lock_version),
              form.hidden_field(:request_key, value: SecureRandom.uuid),
              form.label(:region, "New region for #{account.name}", for: "region_#{account.id}"),
              form.select(:region, Account::REGIONS - [ account.region ], {}, id: "region_#{account.id}"),
              form.submit("Change region for #{account.name}", class: "rounded border px-4 py-2") ])
          }
        end
      end
    end
    panel "Your change receipts", id: "receipts" do
      ReversibleChange.where(admin_user: current_admin_user).includes(:account, :events).order(id: :desc).limit(10).each do |receipt|
        div id: "receipt_#{receipt.id}" do
          para "#{receipt.account.name}: #{receipt.before_value} → #{receipt.after_value}"
          para "Undo #{receipt.undo_state}. Expires #{receipt.expires_at.utc.iso8601}.", role: "status"
          if receipt.undo_state == "available"
            text_node button_to("Undo region change", admin_reversible_actions_undo_path, method: :post,
              params: { receipt_id: receipt.id }, class: "rounded border px-4 py-2")
          end
          ul do
            receipt.events.order(:id).each do |event|
              li "#{event.kind}: #{event.from_value} → #{event.to_value}; administrator #{event.admin_user_id}; #{event.created_at.utc.iso8601}"
            end
          end
        end
      end
    end
    panel "Implementation" do
      para "Two commands append separate immutable audit rows. Undo requires the recorded account revision and current editing permission; retries return the existing receipt. No browser timer grants authority."
      para link_to("Read the undo contract", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/reversible-actions.md")
    end
  end
end
