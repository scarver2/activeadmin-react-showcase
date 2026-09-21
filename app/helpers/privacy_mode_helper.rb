# app/helpers/privacy_mode_helper.rb
# frozen_string_literal: true

module PrivacyModeHelper
  def showcase_privacy_enabled?
    preference = session[:showcase_privacy]
    return true unless preference.is_a?(Hash) && preference["user_id"] == current_admin_user&.id

    preference["enabled"] != false
  end
end
