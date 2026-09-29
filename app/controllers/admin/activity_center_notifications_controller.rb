# app/controllers/admin/activity_notifications_controller.rb
# frozen_string_literal: true

module Admin
  class ActivityCenterNotificationsController < ApplicationController
    before_action :authenticate_admin_user!

    def index
      notifications = current_admin_user.notifications.includes(:event).newest_first.limit(100)
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
      notification = current_admin_user.notifications.includes(:event).find(params[:id])
      ActivityCenter::SetReadState.call(
        notification:,
        read: ActiveModel::Type::Boolean.new.cast(params.require(:read))
      )
      ActivityCenter::UnreadProjection.broadcast(current_admin_user)
      respond_to do |format|
        format.html { redirect_to "/admin/activity_center", notice: "Notification state updated." }
        format.json { render json: ActivityCenter::Serializer.new(notification).as_json }
      end
    end
  end
end
