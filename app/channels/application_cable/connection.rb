# app/channels/application_cable/connection.rb
# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_admin_user

    def connect
      self.current_admin_user = env["warden"]&.user(:admin_user)
      reject_unauthorized_connection unless current_admin_user
    end
  end
end
