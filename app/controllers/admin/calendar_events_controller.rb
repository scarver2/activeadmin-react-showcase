# app/controllers/admin/calendar_events_controller.rb
# frozen_string_literal: true

module Admin
  class CalendarEventsController < ApplicationController
    before_action :authenticate_admin_user!

    def index
      render json: Calendar::EventQuery.new(
        admin_user: current_admin_user,
        starts_at: params[:start],
        ends_at: params[:end]
      ).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :bad_request
    end

    def create
      event = Calendar::SaveEvent.call(admin_user: current_admin_user, attributes: event_params)
      render json: { event: Calendar::EventSerializer.new(event).as_json }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_invalid(error)
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    def update
      event = Calendar::SaveEvent.call(
        admin_user: current_admin_user,
        attributes: event_params,
        event: current_admin_user.schedule_events.find(params[:id]),
        expected_lock_version: params[:lock_version]
      )
      render json: { event: Calendar::EventSerializer.new(event).as_json }
    rescue ActiveRecord::RecordInvalid => error
      render_invalid(error)
    rescue Calendar::SaveEvent::StaleWrite => error
      render json: { error: error.message }, status: :conflict
    rescue ArgumentError => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def event_params
      params.require(:event).permit(:ends_at, :location, :notes, :starts_at, :time_zone, :title)
    end

    def render_invalid(error)
      render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    end
  end
end
