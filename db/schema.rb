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

ActiveRecord::Schema[8.1].define(version: 2026_09_07_350000) do
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

  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_notifications", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.string "deep_link", null: false
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.datetime "read_at"
    t.integer "sequence", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "occurred_at"], name: "index_activity_notifications_on_admin_user_id_and_occurred_at"
    t.index ["admin_user_id", "sequence"], name: "index_activity_notifications_on_admin_user_id_and_sequence", unique: true
    t.index ["admin_user_id"], name: "index_activity_notifications_on_admin_user_id"
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

  create_table "agent_events", force: :cascade do |t|
    t.integer "agent_run_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.json "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.integer "progress", default: 0, null: false
    t.integer "sequence", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_run_id", "sequence"], name: "index_agent_events_on_agent_run_id_and_sequence", unique: true
    t.index ["agent_run_id"], name: "index_agent_events_on_agent_run_id"
    t.check_constraint "kind IN ('status', 'response', 'citation', 'result')", name: "agent_events_valid_kind"
    t.check_constraint "progress BETWEEN 0 AND 100", name: "agent_events_progress_range"
  end

  create_table "agent_runs", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.datetime "cancel_requested_at"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "progress", default: 0, null: false
    t.string "prompt", null: false
    t.string "public_id", null: false
    t.string "state", default: "queued", null: false
    t.string "summary"
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "created_at"], name: "index_agent_runs_on_admin_user_id_and_created_at"
    t.index ["admin_user_id"], name: "index_agent_runs_on_admin_user_id"
    t.index ["public_id"], name: "index_agent_runs_on_public_id", unique: true
    t.check_constraint "progress BETWEEN 0 AND 100", name: "agent_runs_progress_range"
    t.check_constraint "state IN ('queued', 'running', 'completed', 'cancelled')", name: "agent_runs_valid_state"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "author_id", null: false
    t.text "body", null: false
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.integer "sequence", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_chat_messages_on_author_id"
    t.index ["chat_room_id", "sequence"], name: "index_chat_messages_on_chat_room_id_and_sequence", unique: true
    t.index ["chat_room_id"], name: "index_chat_messages_on_chat_room_id"
    t.check_constraint "length(body) BETWEEN 1 AND 500", name: "chat_messages_body_length"
  end

  create_table "chat_participants", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_room_id", "key"], name: "index_chat_participants_on_chat_room_id_and_key", unique: true
    t.index ["chat_room_id"], name: "index_chat_participants_on_chat_room_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "public_id", null: false
    t.datetime "updated_at", null: false
    t.index ["public_id"], name: "index_chat_rooms_on_public_id", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "job_title", null: false
    t.string "last_name", null: false
    t.string "relationship_role", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "last_name", "first_name"], name: "index_contacts_on_account_id_and_last_name_and_first_name"
    t.index ["account_id", "relationship_role"], name: "index_contacts_on_account_id_and_relationship_role"
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["email"], name: "index_contacts_on_email", unique: true
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

  create_table "hierarchy_nodes", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "parent_id"
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "parent_id", "position"], name: "idx_on_admin_user_id_parent_id_position_b8a7064ddd"
    t.index ["admin_user_id"], name: "index_hierarchy_nodes_on_admin_user_id"
    t.index ["parent_id"], name: "index_hierarchy_nodes_on_parent_id"
    t.check_constraint "parent_id IS NULL OR parent_id != id", name: "hierarchy_nodes_not_self_parented"
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
    t.string "cancel_idempotency_key"
    t.datetime "cancel_requested_at"
    t.datetime "claim_expires_at"
    t.integer "claim_generation", default: 0, null: false
    t.string "claim_key"
    t.datetime "created_at", null: false
    t.string "error"
    t.datetime "finished_at"
    t.string "kind", default: "successful_demo", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "message", default: "Waiting for a worker", null: false
    t.integer "progress", default: 0, null: false
    t.string "public_id", null: false
    t.string "request_idempotency_key"
    t.string "result"
    t.integer "retry_of_id"
    t.datetime "started_at"
    t.string "state", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "created_at"], name: "index_operations_on_admin_user_id_and_created_at"
    t.index ["admin_user_id", "request_idempotency_key"], name: "index_operations_on_admin_user_id_and_request_idempotency_key", unique: true, where: "request_idempotency_key IS NOT NULL"
    t.index ["admin_user_id"], name: "index_operations_on_admin_user_id"
    t.index ["claim_key"], name: "index_operations_on_claim_key", unique: true, where: "claim_key IS NOT NULL"
    t.index ["public_id"], name: "index_operations_on_public_id", unique: true
    t.index ["retry_of_id"], name: "index_operations_on_retry_of_id"
    t.check_constraint "(claim_key IS NULL AND claim_expires_at IS NULL) OR (claim_key IS NOT NULL AND claim_expires_at IS NOT NULL)", name: "operations_claim_lease_complete"
    t.check_constraint "claim_generation >= 0", name: "operations_claim_generation_nonnegative"
    t.check_constraint "kind IN ('successful_demo', 'failing_demo')", name: "operations_valid_kind"
    t.check_constraint "progress BETWEEN 0 AND 100", name: "operations_progress_range"
    t.check_constraint "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')", name: "operations_valid_state"
  end

  create_table "schedule_events", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "location"
    t.integer "lock_version", default: 0, null: false
    t.text "notes"
    t.datetime "starts_at", null: false
    t.string "time_zone", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "starts_at", "ends_at"], name: "idx_on_admin_user_id_starts_at_ends_at_e1be735638"
    t.index ["admin_user_id"], name: "index_schedule_events_on_admin_user_id"
    t.check_constraint "ends_at > starts_at", name: "schedule_events_positive_duration"
  end

  create_table "showcase_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "editor_state", null: false
    t.text "rendered_html", null: false
    t.string "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_showcase_articles_on_title"
  end

  create_table "showcase_assets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_showcase_assets_on_title"
  end

  create_table "telemetry_request_samples", force: :cascade do |t|
    t.float "duration_ms", null: false
    t.datetime "occurred_at", null: false
    t.integer "status", null: false
    t.index ["occurred_at"], name: "index_telemetry_request_samples_on_occurred_at"
    t.check_constraint "duration_ms >= 0", name: "telemetry_duration_nonnegative"
    t.check_constraint "status BETWEEN 100 AND 599", name: "telemetry_valid_status"
  end

  create_table "terminal_executions", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.datetime "cancel_requested_at"
    t.string "command_key", null: false
    t.datetime "created_at", null: false
    t.string "display_command", null: false
    t.datetime "finished_at"
    t.string "idempotency_key", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "public_id", null: false
    t.datetime "started_at"
    t.string "state", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "created_at"], name: "index_terminal_executions_on_admin_user_id_and_created_at"
    t.index ["admin_user_id", "idempotency_key"], name: "index_terminal_executions_on_admin_user_id_and_idempotency_key", unique: true
    t.index ["admin_user_id"], name: "index_terminal_executions_on_admin_user_id"
    t.index ["public_id"], name: "index_terminal_executions_on_public_id", unique: true
    t.check_constraint "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')", name: "terminal_executions_valid_state"
  end

  create_table "terminal_outputs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "occurred_at", null: false
    t.integer "sequence", null: false
    t.string "stream", null: false
    t.integer "terminal_execution_id", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["terminal_execution_id", "sequence"], name: "index_terminal_outputs_on_terminal_execution_id_and_sequence", unique: true
    t.index ["terminal_execution_id"], name: "index_terminal_outputs_on_terminal_execution_id"
    t.check_constraint "length(text) BETWEEN 1 AND 500", name: "terminal_outputs_text_length"
    t.check_constraint "stream IN ('stdout', 'stderr', 'system')", name: "terminal_outputs_valid_stream"
  end

  create_table "workflow_items", force: :cascade do |t|
    t.text "context"
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.string "state", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["state", "position"], name: "index_workflow_items_on_state_and_position"
    t.check_constraint "position >= 0", name: "workflow_items_nonnegative_position"
    t.check_constraint "state IN ('backlog', 'ready', 'in_progress', 'review', 'done')", name: "workflow_items_valid_state"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_notifications", "admin_users"
  add_foreign_key "agent_events", "agent_runs"
  add_foreign_key "agent_runs", "admin_users"
  add_foreign_key "chat_messages", "chat_participants", column: "author_id"
  add_foreign_key "chat_messages", "chat_rooms"
  add_foreign_key "chat_participants", "chat_rooms"
  add_foreign_key "contacts", "accounts"
  add_foreign_key "daily_metrics", "accounts"
  add_foreign_key "hierarchy_nodes", "admin_users"
  add_foreign_key "hierarchy_nodes", "hierarchy_nodes", column: "parent_id"
  add_foreign_key "operation_events", "operations"
  add_foreign_key "operations", "admin_users"
  add_foreign_key "operations", "operations", column: "retry_of_id"
  add_foreign_key "schedule_events", "admin_users"
  add_foreign_key "terminal_executions", "admin_users"
  add_foreign_key "terminal_outputs", "terminal_executions"
end
