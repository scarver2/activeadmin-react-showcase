# app/controllers/admin/activity_notifications_controller.rb
# frozen_string_literal: true

module Admin
  class ActivityCenterNotificationsController < ApplicationController
    before_action :authenticate_admin_user!

    def index
      notifications = current_admin_user.activity_notifications.newest_first.limit(100)
      render json: notifications.map { |item| ActivityCenter::Serializer.new(item).as_json }
    end

    def create
      notification = ActivityCenter::Create.call(
        admin_user: current_admin_user,
        attributes: {
          body: "A persisted notification was delivered through Solid Cable.",
          deep_link: "/admin/accounts",
          kind: "account",
          occurred_at: Time.current,
          subject: "Live account activity"
        }
      )
      respond_to do |format|
        format.html { redirect_to "/admin/activity_center", notice: "Notification created." }
        format.json { render json: ActivityCenter::Serializer.new(notification).as_json, status: :created }
      end
    end

    def update
      notification = current_admin_user.activity_notifications.find(params[:id])
      ActiveModel::Type::Boolean.new.cast(params.require(:read)) ? notification.mark_read! : notification.mark_unread!
      render json: ActivityCenter::Serializer.new(notification).as_json
    end
  end
end
