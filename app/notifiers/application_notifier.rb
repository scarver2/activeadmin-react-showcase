# app/notifiers/application_notifier.rb
# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  REQUIRED_PARAMS = %i[body deep_link kind occurred_at subject].freeze

  deliver_by :action_cable do |config|
    config.channel = "ActivityCenterChannel"
    config.message = lambda {
      { type: "notification", notification: ActivityCenter::Serializer.new(self).as_json }
    }
    config.stream = -> { recipient }
  end

  required_params(*REQUIRED_PARAMS)

  validate :activity_kind_is_supported
  validate :deep_link_is_local

  private

  def activity_kind_is_supported
    kind = params.with_indifferent_access[:kind]
    errors.add(:params, "contains an unsupported activity kind") unless kind.in?(ActivityCenter::KINDS)
  end

  def deep_link_is_local
    deep_link = params.with_indifferent_access[:deep_link]
    errors.add(:params, "contains a non-admin deep link") unless deep_link.to_s.start_with?("/admin/")
  end
end
