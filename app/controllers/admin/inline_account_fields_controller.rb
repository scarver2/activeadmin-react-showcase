# app/controllers/admin/inline_account_fields_controller.rb
# frozen_string_literal: true

module Admin
  class InlineAccountFieldsController < ApplicationController
    before_action :authenticate_admin_user!

    def update
      account = Account.find(params[:id])
      InlineEditing::Update.call(
        admin_user: current_admin_user, account:, field: params.require(:field), value: params.require(:value),
        expected_lock_version: params.require(:lock_version)
      )
      render json: InlineEditing::Serializer.new(account).as_json
    rescue InlineEditing::Update::Forbidden => e
      render json: { error: e.message }, status: :forbidden
    rescue InlineEditing::Update::StaleWrite => e
      render json: { error: e.message, account: InlineEditing::Serializer.new(account).as_json }, status: :conflict
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
      message = e.respond_to?(:record) ? e.record.errors.full_messages.to_sentence.presence || "Value is not allowed" : e.message
      render json: { error: message }, status: :unprocessable_content
    end
  end
end
