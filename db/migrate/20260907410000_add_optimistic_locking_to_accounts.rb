# db/migrate/20260907410000_add_optimistic_locking_to_accounts.rb
# frozen_string_literal: true

class AddOptimisticLockingToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :lock_version, :integer, null: false, default: 0
  end
end
