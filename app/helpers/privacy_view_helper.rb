# app/helpers/privacy_view_helper.rb
# frozen_string_literal: true

module PrivacyViewHelper
  def showcase_privacy_view_enabled?
    preference = session[:showcase_privacy_view]
    return false unless preference.is_a?(Hash) && preference["user_id"] == current_admin_user&.id

    preference["enabled"] == true
  end
end
