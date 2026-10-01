# app/services/showcase/palette_commands.rb
# frozen_string_literal: true

module Showcase
  # Adapts two existing domain commands; it does not own their mutation semantics.
  class PaletteCommands
    def initialize(admin_user:)
      raise GlobalSearch::Unauthorized unless admin_user&.persisted?

      @admin_user = admin_user
    end

    def search(query)
      candidates = admin_user.operations.where(state: %w[queued running]).order(id: :desc).limit(5).map do |operation|
        descriptor("cancel", operation)
      end
      candidates += admin_user.notifications.where(dismissed_at: nil).order(id: :desc).limit(5).map do |notification|
        descriptor("dismiss", notification)
      end
      candidates.select { |item| item.fetch(:label).downcase.include?(query.downcase) }
    end

    def find(key)
      action, id = key.to_s.split(":", 2)
      record = case action
      when "cancel" then admin_user.operations.where(state: %w[queued running]).find(id)
      when "dismiss" then admin_user.notifications.where(dismissed_at: nil).find(id)
      else raise ActiveRecord::RecordNotFound
      end
      descriptor(action, record)
    end

    def execute(key)
      item = find(key)
      action, id = key.split(":", 2)
      case action
      when "cancel"
        Operations::Cancel.call(operation: admin_user.operations.find(id), idempotency_key: "palette-cancel:#{id}")
      when "dismiss"
        ActivityCenter::MutateState.call(notification: admin_user.notifications.find(id), mutation: "dismiss")
      end
      item.fetch(:destination)
    end

    private

    attr_reader :admin_user

    def descriptor(action, record)
      key = "#{action}:#{record.id}"
      label = action == "cancel" ? "Cancel operation #{record.public_id}" : "Dismiss notification #{record.id}"
      destination = action == "cancel" ? "/admin/live_jobs?operation_id=#{record.public_id}" : "/admin/activity_center"
      { id: key, kind: "Command", group: "Permitted commands", label:, description: "Requires confirmation; Rails rechecks ownership and availability.",
        url: Rails.application.routes.url_helpers.admin_command_palette_path(command: key), destination: }
    end
  end
end
