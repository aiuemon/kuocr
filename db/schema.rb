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

ActiveRecord::Schema[8.1].define(version: 2026_09_27_010000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
    t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
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
    t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index [ "blob_id", "variation_digest" ], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "auth_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "local_auth_enabled", default: true, null: false
    t.boolean "local_auth_show_on_login", default: true, null: false
    t.boolean "self_signup_enabled", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "identity_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "name", null: false
    t.string "provider_type", null: false
    t.json "settings", default: {}, null: false
    t.boolean "show_on_login", default: true, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index [ "enabled" ], name: "index_identity_providers_on_enabled"
    t.index [ "provider_type" ], name: "index_identity_providers_on_provider_type"
    t.index [ "slug" ], name: "index_identity_providers_on_slug", unique: true
  end

  create_table "image_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "memo"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "user_id" ], name: "index_image_groups_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "image_group_id"
    t.string "name"
    t.datetime "ocr_completed_at"
    t.integer "ocr_duration"
    t.integer "ocr_prompt_pattern_id"
    t.text "ocr_prompt_text"
    t.text "ocr_result"
    t.datetime "purged_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "image_group_id" ], name: "index_images_on_image_group_id"
    t.index [ "ocr_prompt_pattern_id" ], name: "index_images_on_ocr_prompt_pattern_id"
    t.index [ "purged_at" ], name: "index_images_on_purged_at"
    t.index [ "status" ], name: "index_images_on_status"
    t.index [ "user_id" ], name: "index_images_on_user_id"
  end

  create_table "ocr_prompt_patterns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.text "prompt", null: false
    t.datetime "updated_at", null: false
    t.index [ "is_default" ], name: "index_ocr_prompt_patterns_on_is_default"
    t.index [ "position" ], name: "index_ocr_prompt_patterns_on_position"
  end

  create_table "ocr_settings", force: :cascade do |t|
    t.string "api_key", default: ""
    t.datetime "created_at", null: false
    t.string "endpoint", default: ""
    t.string "model", default: ""
    t.json "options", default: {}
    t.text "prompt", default: ""
    t.integer "timeout", default: 300
    t.datetime "updated_at", null: false
  end

  create_table "quota_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "max_storage_per_user_mb", default: 1024
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "var", null: false
    t.index [ "var" ], name: "index_settings_on_var", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.index [ "batch_id" ], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index [ "job_id" ], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.integer "completed_jobs", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "enqueued_at"
    t.datetime "failed_at"
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "finished_at"
    t.text "metadata"
    t.text "on_failure"
    t.text "on_finish"
    t.text "on_success"
    t.integer "total_jobs", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "active_job_batch_id" ], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index [ "finished_at" ], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index [ "concurrency_key", "priority", "job_id" ], name: "index_solid_queue_blocked_executions_for_release"
    t.index [ "expires_at", "concurrency_key" ], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index [ "job_id" ], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index [ "job_id" ], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index [ "process_id", "job_id" ], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index [ "job_id" ], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.bigint "batch_id"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index [ "active_job_id" ], name: "index_solid_queue_jobs_on_active_job_id"
    t.index [ "batch_id" ], name: "index_solid_queue_jobs_on_batch_id"
    t.index [ "class_name" ], name: "index_solid_queue_jobs_on_class_name"
    t.index [ "finished_at" ], name: "index_solid_queue_jobs_on_finished_at"
    t.index [ "queue_name", "finished_at" ], name: "index_solid_queue_jobs_for_filtering"
    t.index [ "scheduled_at", "finished_at" ], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index [ "queue_name" ], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index [ "last_heartbeat_at" ], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index [ "name", "supervisor_id" ], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index [ "supervisor_id" ], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index [ "job_id" ], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index [ "priority", "job_id" ], name: "index_solid_queue_poll_all"
    t.index [ "queue_name", "priority", "job_id" ], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index [ "job_id" ], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index [ "task_key", "run_at" ], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index [ "key" ], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index [ "static" ], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index [ "job_id" ], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index [ "scheduled_at", "priority", "job_id" ], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index [ "expires_at" ], name: "index_solid_queue_semaphores_on_expires_at"
    t.index [ "key", "value" ], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index [ "key" ], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.integer "priority", default: 3, null: false
    t.boolean "priority_manually_set", default: false, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "sessions_invalidated_at"
    t.datetime "updated_at", null: false
    t.string "webauthn_id"
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "reset_password_token" ], name: "index_users_on_reset_password_token", unique: true
    t.index [ "webauthn_id" ], name: "index_users_on_webauthn_id", unique: true
    t.check_constraint "priority BETWEEN 1 AND 5", name: "chk_users_priority_range"
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.string "authenticator_type"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.datetime "last_used_at"
    t.string "nickname"
    t.string "public_key", null: false
    t.bigint "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index [ "external_id" ], name: "index_webauthn_credentials_on_external_id", unique: true
    t.index [ "user_id" ], name: "index_webauthn_credentials_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "image_groups", "users"
  add_foreign_key "images", "image_groups"
  add_foreign_key "images", "ocr_prompt_patterns"
  add_foreign_key "images", "users"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "webauthn_credentials", "users"
end
