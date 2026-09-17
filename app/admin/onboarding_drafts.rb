# app/admin/onboarding_drafts.rb
# frozen_string_literal: true

ActiveAdmin.register OnboardingDraft do
  menu false
  scope_to :current_admin_user
  permit_params :account_kind, :company_name, :compliance_contact, :contact_email, :current_step
end
