# db/migrate/20260905221504_create_daily_metrics.rb
# frozen_string_literal: true

class CreateDailyMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_metrics do |t|
      t.references :account, null: false, foreign_key: true
      t.date :recorded_on, null: false
      t.integer :active_users, default: 0, null: false
      t.integer :revenue_cents, default: 0, null: false
      t.integer :request_count, default: 0, null: false
      t.integer :error_count, default: 0, null: false
      t.integer :p95_ms, default: 0, null: false

      t.timestamps
    end


    add_index :daily_metrics, %i[account_id recorded_on], unique: true
    add_index :daily_metrics, :recorded_on
  end
end
