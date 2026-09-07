# db/migrate/20260906110000_add_operation_claim_generation.rb
# frozen_string_literal: true

class AddOperationClaimGeneration < ActiveRecord::Migration[8.1]
  def change
    add_column :operations, :claim_generation, :integer, null: false, default: 0
    add_index :operations, :claim_key, unique: true, where: "claim_key IS NOT NULL"
    add_check_constraint :operations, "claim_generation >= 0", name: "operations_claim_generation_nonnegative"
    add_check_constraint :operations,
                         "(claim_key IS NULL AND claim_expires_at IS NULL) OR " \
                         "(claim_key IS NOT NULL AND claim_expires_at IS NOT NULL)",
                         name: "operations_claim_lease_complete"
  end
end
