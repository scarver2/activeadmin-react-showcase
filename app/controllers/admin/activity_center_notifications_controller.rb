# app/controllers/admin/activity_notifications_controller.rb
# frozen_string_literal: true

module Admin
  class ActivityCenterNotificationsController < ApplicationController
    before_action :authenticate_admin_user!

    def index
      notifications = inbox.notifications(filter: params.fetch(:filter, "all"))
      render json: notifications.map { |item| ActivityCenter::Serializer.new(item).as_json }
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    def create
      notification = ActivityCenter::CreateWorkflowReview.call(admin_user: current_admin_user)
      respond_to do |format|
        format.html { redirect_to "/admin/activity_center", notice: "Notification created." }
        format.json { render json: ActivityCenter::Serializer.new(notification).as_json, status: :created }
      end
    end

    def update
      notification = current_admin_user.notifications.includes(:event).find(params[:id])
      ActivityCenter::SetReadState.call(
        notification:,
        read: ActiveModel::Type::Boolean.new.cast(params.require(:read))
      )
      respond_with_notification(notification, notice: "Notification state updated.")
    end

    def dismiss
      mutate("dismiss", notice: "Notification dismissed.")
    end

    def restore
      mutate("restore", notice: "Notification restored.")
    end

    def snooze
      mutate("snooze", notice: "Notification snoozed for one hour.")
    end

    def perform_action
      notification = find_notification
      item = ActivityCenter::PerformAction.call(notification:)
      respond_to do |format|
        format.html { redirect_to "/admin/activity_center", notice: "#{item.title} completed." }
        format.json { render json: ActivityCenter::Serializer.new(notification.reload).as_json }
      end
    rescue ActivityCenter::UnsupportedAction => error
      respond_to do |format|
        format.html { redirect_to "/admin/activity_center", alert: error.message }
        format.json { render json: { error: error.message }, status: :unprocessable_content }
      end
    end

    private

    def find_notification
      current_admin_user.notifications.includes(event: :record).find(params[:id])
    end

    def inbox
      ActivityCenter::Inbox.new(admin_user: current_admin_user)
    end

    def mutate(mutation, notice:)
      notification = ActivityCenter::MutateState.call(notification: find_notification, mutation:)
      respond_with_notification(notification, notice:)
    end

    def respond_with_notification(notification, notice:)
      respond_to do |format|
        format.html { redirect_to "/admin/activity_center", notice: }
        format.json { render json: ActivityCenter::Serializer.new(notification.reload).as_json }
      end
    end
  end
end
