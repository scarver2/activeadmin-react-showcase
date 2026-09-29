# app/services/activity_center/set_read_state.rb
# frozen_string_literal: true

module ActivityCenter
  class SetReadState
    def self.call(notification:, read:)
      if read
        notification.mark_as_read! unless notification.read?
      else
        notification.mark_as_unread! unless notification.unread?
      end
      notification
    end
  end
end
