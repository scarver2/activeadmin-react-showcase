# db/migrate/20260907300000_create_contacts.rb
# frozen_string_literal: true

class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :job_title, null: false
      t.string :last_name, null: false
      t.string :relationship_role, null: false

      t.timestamps
    end

    add_index :contacts, :email, unique: true
    add_index :contacts, %i[account_id last_name first_name]
    add_index :contacts, %i[account_id relationship_role]
  end
end
