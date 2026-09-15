# app/services/onboarding/save_draft.rb
# frozen_string_literal: true

module Onboarding
  class SaveDraft
    class StaleWrite < StandardError; end
    ATTRIBUTES = %i[account_kind company_name compliance_contact contact_email current_step].freeze

    def self.call(admin_user:, draft:, attributes:, expected_lock_version:, submit: false)
      raise StaleWrite, "This draft changed elsewhere. Reload it before saving." unless draft.lock_version == expected_lock_version.to_i
      raise ActiveRecord::RecordNotFound unless draft.admin_user == admin_user

      draft.assign_attributes(attributes.slice(*ATTRIBUTES).to_h)
      draft.status = "submitted" if submit
      draft.submitted_at = Time.current if submit
      draft.save!
      draft
    rescue ActiveRecord::StaleObjectError
      raise StaleWrite, "This draft changed elsewhere. Reload it before saving."
    end
  end
end
