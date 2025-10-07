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

ActiveRecord::Schema[8.0].define(version: 2025_10_07_025158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "status"
    t.uuid "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "start_time"], name: "index_appointments_on_business_id_and_start_time"
    t.index ["business_id"], name: "index_appointments_on_business_id"
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["status"], name: "index_appointments_on_status"
  end

  create_table "businesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "timezone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_businesses_on_name"
  end

  create_table "consent_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.text "consent_text"
    t.datetime "consented_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "event_type", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.index ["consented_at"], name: "index_consent_logs_on_consented_at"
    t.index ["customer_id"], name: "index_consent_logs_on_customer_id"
    t.index ["event_type"], name: "index_consent_logs_on_event_type"
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "email"
    t.uuid "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sms_consent_status", default: 1, null: false
    t.datetime "opted_out_at"
    t.index ["business_id", "phone"], name: "index_customers_on_business_id_and_phone", unique: true
    t.index ["business_id"], name: "index_customers_on_business_id"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["opted_out_at"], name: "index_customers_on_opted_out_at"
    t.index ["sms_consent_status"], name: "index_customers_on_sms_consent_status"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "customer_id", null: false
    t.text "body"
    t.integer "direction"
    t.integer "status"
    t.jsonb "metadata"
    t.uuid "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "created_at"], name: "index_messages_on_business_id_and_created_at"
    t.index ["business_id"], name: "index_messages_on_business_id"
    t.index ["customer_id"], name: "index_messages_on_customer_id"
    t.index ["direction"], name: "index_messages_on_direction"
    t.index ["status"], name: "index_messages_on_status"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.uuid "business_id"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_users_on_business_id"
    t.index ["email", "business_id"], name: "index_users_on_email_and_business_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "appointments", "businesses"
  add_foreign_key "appointments", "customers"
  add_foreign_key "consent_logs", "customers"
  add_foreign_key "customers", "businesses"
  add_foreign_key "messages", "businesses"
  add_foreign_key "messages", "customers"
  add_foreign_key "users", "businesses"
end
