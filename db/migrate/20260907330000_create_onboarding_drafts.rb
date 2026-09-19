# db/migrate/20260907330000_create_onboarding_drafts.rb
# frozen_string_literal: true

class CreateOnboardingDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :onboarding_drafts do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :company_name, null: false, default: ""
      table.string :contact_email, null: false, default: ""
      table.string :account_kind, null: false, default: "standard"
      table.string :compliance_contact, null: false, default: ""
      table.string :status, null: false, default: "draft"
      table.integer :current_step, null: false, default: 1
      table.integer :lock_version, null: false, default: 0
      table.datetime :submitted_at
      table.timestamps
    end

    add_index :onboarding_drafts, %i[admin_user_id status]
    add_check_constraint :onboarding_drafts, "current_step BETWEEN 1 AND 3", name: "onboarding_drafts_step"
    add_check_constraint :onboarding_drafts, "status IN ('draft', 'submitted')", name: "onboarding_drafts_status"
  end
end
