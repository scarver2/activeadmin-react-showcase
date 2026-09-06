# db/migrate/20260906090002_constrain_operation_lifecycles.rb
# frozen_string_literal: true

class ConstrainOperationLifecycles < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :operations,
                         "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')",
                         name: "operations_valid_state"
    add_check_constraint :operations,
                         "kind IN ('successful_demo', 'failing_demo')",
                         name: "operations_valid_kind"
    add_check_constraint :operation_events,
                         "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')",
                         name: "operation_events_valid_state"
  end
end
