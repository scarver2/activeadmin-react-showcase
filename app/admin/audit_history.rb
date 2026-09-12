# app/admin/audit_history.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Audit History" do
  menu label: "Audit History", parent: "Data & Workflows", priority: 8

  content title: "PaperTrail audit history" do
    profile = current_admin_user.audit_profiles.first
    panel("Demo") { para "Filter immutable PaperTrail versions and preview a Rails-owned restoration without mutating history." }
    if profile
      history = AuditHistory::ProfileHistory.new(profile)
      react_component("AuditHistory", props: { history: history.as_json, name: profile.name, previewUrl: admin_audit_profile_history_path(profile) }, fallback: -> {
        table_for profile.versions.order(created_at: :desc) do
          column(:event)
          column(:actor) { |version| version.whodunnit.presence || "seed" }
          column(:timestamp, &:created_at)
          column(:changes) { |version| version.changeset.slice(*AuditHistory::ProfileHistory::FIELDS).to_json }
        end
      })
    else
      para "No versioned profile history exists. Run bin/rails db:seed."
    end
    panel("Ruby") { para "PaperTrail records provenance and paper_trail_diff 0.12.0 produces immutable structured restoration comparisons." }
    panel("JavaScript") { para "React filters fields and selects versions; it never reifies or restores records." }
    panel("Architecture") { para link_to("Read the audit guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/audit-history.md") }
  end
end
