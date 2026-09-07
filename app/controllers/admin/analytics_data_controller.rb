# app/controllers/admin/analytics_data_controller.rb
# frozen_string_literal: true

module Admin
  class AnalyticsDataController < ApplicationController
    before_action :require_admin_user

    def show
      render json: Showcase::AnalyticsSnapshot.new(
        start_date: date_param(:start_date, 29.days.ago.to_date),
        end_date: date_param(:end_date, Date.current)
      ).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def date_param(name, default)
      return default if params[name].blank?

      Date.iso8601(params[name].to_s)
    rescue Date::Error
      raise ArgumentError, "#{name} must be an ISO 8601 date"
    end

    def require_admin_user
      head :unauthorized unless admin_user_signed_in?
    end
  end
end
