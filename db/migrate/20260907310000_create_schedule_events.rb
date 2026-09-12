# db/migrate/20260907310000_create_schedule_events.rb
# frozen_string_literal: true

class CreateScheduleEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_events do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.datetime :ends_at, null: false
      table.integer :lock_version, default: 0, null: false
      table.string :location
      table.text :notes
      table.datetime :starts_at, null: false
      table.string :time_zone, null: false
      table.string :title, null: false
      table.timestamps
    end

    add_index :schedule_events, %i[admin_user_id starts_at ends_at]
    add_check_constraint :schedule_events, "ends_at > starts_at", name: "schedule_events_positive_duration"
  end
end
