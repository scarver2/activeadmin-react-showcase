# app/services/activity_center/set_read_state.rb
# frozen_string_literal: true

module ActivityCenter
  class SetReadState
    def self.call(notification:, read:)
      ActivityCenter::MutateState.call(notification:, mutation: "read", read:)
    end
  end
end
