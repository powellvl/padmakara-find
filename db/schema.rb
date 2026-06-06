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

ActiveRecord::Schema[8.0].define(version: 2026_06_06_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.boolean "primary", default: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_triage_proposals", force: :cascade do |t|
    t.bigint "catalogued_file_id", null: false
    t.string "proposed_title_tibetan"
    t.string "proposed_title_wylie"
    t.string "proposed_title_phonetic"
    t.string "proposed_language"
    t.boolean "is_prayer_text", default: true
    t.string "confidence"
    t.string "model_used"
    t.text "ai_notes"
    t.jsonb "proposed_deity_names", default: []
    t.jsonb "proposed_school_names", default: []
    t.jsonb "proposed_author_names", default: []
    t.jsonb "raw_response"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogued_file_id"], name: "index_ai_triage_proposals_on_catalogued_file_id"
    t.index ["confidence"], name: "index_ai_triage_proposals_on_confidence"
    t.index ["status"], name: "index_ai_triage_proposals_on_status"
  end

  create_table "authors", force: :cascade do |t|
    t.string "name_english"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authors_texts", force: :cascade do |t|
    t.integer "author_id", null: false
    t.integer "text_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "text_id"], name: "index_authors_texts_on_author_id_and_text_id", unique: true
    t.index ["author_id"], name: "index_authors_texts_on_author_id"
    t.index ["text_id"], name: "index_authors_texts_on_text_id"
  end

  create_table "catalogued_files", force: :cascade do |t|
    t.string "sha256_checksum", null: false
    t.bigint "byte_size", null: false
    t.string "content_type", default: "application/octet-stream", null: false
    t.integer "triage_state", default: 0, null: false
    t.datetime "first_seen_at", null: false
    t.datetime "last_scan_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "extracted_text"
    t.integer "extraction_status", default: 0, null: false
    t.tsvector "content_tsvector"
    t.bigint "version_id"
    t.index ["content_tsvector"], name: "index_catalogued_files_on_content_tsvector", using: :gin
    t.index ["content_type"], name: "index_catalogued_files_on_content_type"
    t.index ["extracted_text"], name: "index_catalogued_files_on_extracted_text_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["extraction_status"], name: "index_catalogued_files_on_extraction_status"
    t.index ["sha256_checksum"], name: "index_catalogued_files_on_sha256_checksum", unique: true
    t.index ["triage_state"], name: "index_catalogued_files_on_triage_state"
    t.index ["version_id"], name: "index_catalogued_files_on_version_id"
  end

  create_table "deities", force: :cascade do |t|
    t.string "name_tibetan"
    t.string "name_sanskrit"
    t.string "name_english"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deities_texts", force: :cascade do |t|
    t.integer "deity_id", null: false
    t.integer "text_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deity_id", "text_id"], name: "index_deities_texts_on_deity_id_and_text_id", unique: true
    t.index ["deity_id"], name: "index_deities_texts_on_deity_id"
    t.index ["text_id"], name: "index_deities_texts_on_text_id"
  end

  create_table "file_locations", force: :cascade do |t|
    t.bigint "catalogued_file_id", null: false
    t.text "path", null: false
    t.datetime "mtime", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "missing_since"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogued_file_id"], name: "index_file_locations_on_catalogued_file_id"
    t.index ["last_seen_at"], name: "index_file_locations_on_last_seen_at"
    t.index ["missing_since"], name: "index_file_locations_on_missing_since"
    t.index ["path"], name: "index_file_locations_on_path", unique: true
  end

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schools_texts", force: :cascade do |t|
    t.integer "school_id", null: false
    t.integer "text_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "text_id"], name: "index_schools_texts_on_school_id_and_text_id", unique: true
    t.index ["school_id"], name: "index_schools_texts_on_school_id"
    t.index ["text_id"], name: "index_schools_texts_on_text_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.string "taggable_type", null: false
    t.integer "taggable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_id_and_taggable_type_and_taggable_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags_texts", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "text_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "text_id"], name: "index_tags_texts_on_tag_id_and_text_id", unique: true
    t.index ["tag_id"], name: "index_tags_texts_on_tag_id"
    t.index ["text_id"], name: "index_tags_texts_on_text_id"
  end

  create_table "texts", force: :cascade do |t|
    t.string "title_tibetan"
    t.string "title_phonetics"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title_wylie"
  end

  create_table "translations", force: :cascade do |t|
    t.integer "text_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "language_id"
    t.index ["language_id"], name: "index_translations_on_language_id"
    t.index ["text_id", "language_id"], name: "index_translations_on_text_id_and_language_id", unique: true
    t.index ["text_id"], name: "index_translations_on_text_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.integer "translation_id", null: false
    t.string "name"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "subtitle"
    t.index ["name", "translation_id"], name: "index_versions_on_name_and_translation_id", unique: true
    t.index ["translation_id"], name: "index_versions_on_translation_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_triage_proposals", "catalogued_files"
  add_foreign_key "authors_texts", "authors", on_delete: :cascade
  add_foreign_key "authors_texts", "texts", on_delete: :cascade
  add_foreign_key "catalogued_files", "versions"
  add_foreign_key "deities_texts", "deities", on_delete: :cascade
  add_foreign_key "deities_texts", "texts", on_delete: :cascade
  add_foreign_key "file_locations", "catalogued_files"
  add_foreign_key "schools_texts", "schools", on_delete: :cascade
  add_foreign_key "schools_texts", "texts", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tags_texts", "tags", on_delete: :cascade
  add_foreign_key "tags_texts", "texts", on_delete: :cascade
  add_foreign_key "translations", "languages"
  add_foreign_key "translations", "texts"
  add_foreign_key "versions", "translations"
end
