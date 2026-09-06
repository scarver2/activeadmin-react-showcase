# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_06_090002) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "plan", null: false
    t.string "region", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_accounts_on_name", unique: true
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.integer "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "daily_metrics", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "active_users", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "error_count", default: 0, null: false
    t.integer "p95_ms", default: 0, null: false
    t.date "recorded_on", null: false
    t.integer "request_count", default: 0, null: false
    t.integer "revenue_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "recorded_on"], name: "index_daily_metrics_on_account_id_and_recorded_on", unique: true
    t.index ["account_id"], name: "index_daily_metrics_on_account_id"
    t.index ["recorded_on"], name: "index_daily_metrics_on_recorded_on"
  end

  create_table "operation_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error"
    t.string "idempotency_key", null: false
    t.string "message", null: false
    t.datetime "occurred_at", null: false
    t.integer "operation_id", null: false
    t.integer "progress", null: false
    t.string "result"
    t.integer "sequence", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_operation_events_on_idempotency_key", unique: true
    t.index ["operation_id", "sequence"], name: "index_operation_events_on_operation_id_and_sequence", unique: true
    t.index ["operation_id"], name: "index_operation_events_on_operation_id"
    t.check_constraint "progress BETWEEN 0 AND 100", name: "operation_events_progress_range"
    t.check_constraint "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')", name: "operation_events_valid_state"
  end

  create_table "operations", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.datetime "cancel_requested_at"
    t.datetime "created_at", null: false
    t.string "error"
    t.datetime "finished_at"
    t.string "kind", default: "successful_demo", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "message", default: "Waiting for a worker", null: false
    t.integer "progress", default: 0, null: false
    t.string "public_id", null: false
    t.string "result"
    t.integer "retry_of_id"
    t.datetime "started_at"
    t.string "state", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "created_at"], name: "index_operations_on_admin_user_id_and_created_at"
    t.index ["admin_user_id"], name: "index_operations_on_admin_user_id"
    t.index ["public_id"], name: "index_operations_on_public_id", unique: true
    t.index ["retry_of_id"], name: "index_operations_on_retry_of_id"
    t.check_constraint "kind IN ('successful_demo', 'failing_demo')", name: "operations_valid_kind"
    t.check_constraint "progress BETWEEN 0 AND 100", name: "operations_progress_range"
    t.check_constraint "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')", name: "operations_valid_state"
  end

  add_foreign_key "daily_metrics", "accounts"
  add_foreign_key "operation_events", "operations"
  add_foreign_key "operations", "admin_users"
  add_foreign_key "operations", "operations", column: "retry_of_id"
end
