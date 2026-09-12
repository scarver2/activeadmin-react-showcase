# db/migrate/20260907250000_create_agent_runs.rb
# frozen_string_literal: true

class CreateAgentRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_runs do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :prompt, null: false
      t.string :state, null: false, default: "queued"
      t.integer :progress, null: false, default: 0
      t.string :summary
      t.datetime :cancel_requested_at
      t.datetime :finished_at
      t.timestamps
    end
    add_index :agent_runs, :public_id, unique: true
    add_index :agent_runs, %i[admin_user_id created_at]
    add_check_constraint :agent_runs, "state IN ('queued', 'running', 'completed', 'cancelled')", name: "agent_runs_valid_state"
    add_check_constraint :agent_runs, "progress BETWEEN 0 AND 100", name: "agent_runs_progress_range"

    create_table :agent_events do |t|
      t.references :agent_run, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :kind, null: false
      t.integer :progress, null: false
      t.text :content, null: false
      t.json :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :agent_events, %i[agent_run_id sequence], unique: true
    add_check_constraint :agent_events,
                         "kind IN ('status', 'response', 'citation', 'result')",
                         name: "agent_events_valid_kind"
    add_check_constraint :agent_events, "progress BETWEEN 0 AND 100", name: "agent_events_progress_range"
  end
end
