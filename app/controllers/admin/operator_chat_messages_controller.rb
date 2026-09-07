# app/controllers/admin/operator_chat_messages_controller.rb
# frozen_string_literal: true

module Admin
  class OperatorChatMessagesController < ApplicationController
    before_action :authenticate_admin_user!
    before_action :load_room

    def create
      message = OperatorChat::PostMessage.call(room: @room, body: params[:body])
      respond_to do |format|
        format.html { redirect_to admin_operator_chat_path, notice: "Synthetic message sent." }
        format.json { render json: OperatorChat::Serializer.new(message).as_json, status: :created }
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html { redirect_to admin_operator_chat_path, alert: e.record.errors.full_messages.to_sentence }
        format.json { render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content }
      end
    end

    def reset
      messages = OperatorChat::Reset.call(room: @room)
      respond_to do |format|
        format.html { redirect_to admin_operator_chat_path, notice: "Synthetic conversation reset." }
        format.json { render json: messages.map { |message| OperatorChat::Serializer.new(message).as_json } }
      end
    end

    private

    def load_room
      @room = ChatRoom.find_by!(public_id: params[:room_id])
    end
  end
end
