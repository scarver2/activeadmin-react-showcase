# app/models/onboarding_draft.rb
# frozen_string_literal: true

class OnboardingDraft < ApplicationRecord
  ACCOUNT_KINDS = %w[regulated standard].freeze

  belongs_to :admin_user

  validates :account_kind, inclusion: { in: ACCOUNT_KINDS }
  validates :company_name, presence: true, if: :validating_company?
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :validating_contact?
  validates :compliance_contact, presence: true, if: :regulated_submission?

  def submitted? = status == "submitted"

  private

  def validating_company? = current_step >= 2 || submitted?
  def validating_contact? = current_step >= 3 || submitted?
  def regulated_submission? = submitted? && account_kind == "regulated"
end
