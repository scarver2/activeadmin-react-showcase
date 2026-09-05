# db/schema.rb
# frozen_string_literal: true

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

ActiveRecord::Schema[8.1].define(version: 2026_09_05_221504) do
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

  add_foreign_key "daily_metrics", "accounts"
end
