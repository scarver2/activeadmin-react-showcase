# app/admin/onboarding_wizard.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Onboarding Wizard" do
  menu label: "Onboarding Wizard", parent: "Data & Workflows", priority: 5

  content title: "Rails-authoritative Onboarding Wizard" do
    draft = current_admin_user.onboarding_drafts.where(status: "draft").first_or_create!
    props = { draft: draft.as_json(only: %i[id account_kind company_name compliance_contact contact_email current_step lock_version status]), updateUrl: admin_onboarding_draft_path(draft) }

    panel "Demo" do
      para "Move through conditional account setup, persist a resumable draft, review it, and submit it. Rails owns validation, transitions, authorization, and concurrency."
    end
    react_component("OnboardingWizard", props:, fallback: -> {
      active_admin_form_for draft, url: admin_onboarding_draft_path(draft), method: :patch do |form|
        form.inputs do
          form.input :company_name
          form.input :contact_email
          form.input :account_kind, as: :select, collection: OnboardingDraft::ACCOUNT_KINDS
          form.input :compliance_contact
          form.input :current_step, as: :hidden
          form.input :lock_version, as: :hidden
        end
        form.actions
      end
    })
    panel("Ruby") { para "Onboarding::SaveDraft applies owner scope, step-aware validation, optimistic locking, and final submission semantics." }
    panel("JavaScript") { para "React owns conditional presentation, progress, error focus, and review interaction; every next or back action persists through Rails." }
    panel("Architecture") { para link_to("Read the wizard guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/onboarding-wizard.md") }
  end
end
