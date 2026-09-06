# db/migrate/20260905221459_create_accounts.rb
# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :plan, null: false
      t.string :region, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :accounts, :name, unique: true
    add_index :accounts, :status
  end
end
