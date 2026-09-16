# app/services/audit_history/profile_history.rb
# frozen_string_literal: true

module AuditHistory
  class ProfileHistory
    FIELDS = %w[name plan preferences].freeze

    def initialize(profile) = @profile = profile

    def as_json
      @profile.versions.order(:created_at, :id).map do |version|
        changes = version.changeset.slice(*FIELDS).transform_values { |from, to| { from:, to: } }
        { actor: version.whodunnit.presence || "seed", at: version.created_at.iso8601, changes:, event: version.event, id: version.id }
      end
    end

    def preview(version_id)
      version = @profile.versions.find(version_id)
      PaperTrailDiff.compare(version, @profile, ignore: %i[updated_at]).to_h
    end
  end
end
