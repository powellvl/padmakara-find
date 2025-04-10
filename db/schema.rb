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

ActiveRecord::Schema[8.0].define(version: 2025_04_09_135108) do
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
  add_foreign_key "deities_texts", "deities", on_delete: :cascade
  add_foreign_key "deities_texts", "texts", on_delete: :cascade
  add_foreign_key "schools_texts", "schools", on_delete: :cascade
  add_foreign_key "schools_texts", "texts", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "tags_texts", "tags", on_delete: :cascade
  add_foreign_key "tags_texts", "texts", on_delete: :cascade
  add_foreign_key "translations", "languages"
  add_foreign_key "translations", "texts"
  add_foreign_key "versions", "translations"
end
