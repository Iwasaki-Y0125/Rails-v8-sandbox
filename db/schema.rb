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

ActiveRecord::Schema[8.0].define(version: 2026_01_15_152401) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "matching_excluded_terms", force: :cascade do |t|
    t.text "term", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_matching_excluded_terms_on_enabled"
    t.index ["term"], name: "index_matching_excluded_terms_on_term", unique: true
  end

  create_table "post_terms", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "term_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "term_id"], name: "index_post_terms_on_post_id_and_term_id", unique: true
    t.index ["post_id"], name: "index_post_terms_on_post_id"
    t.index ["term_id", "post_id"], name: "index_post_terms_on_term_id_and_post_id"
    t.index ["term_id"], name: "index_post_terms_on_term_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.float "sentiment_score", default: 0.0, null: false
    t.string "visibility", default: "public", null: false
    t.string "reply_mode", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["visibility", "reply_mode"], name: "index_posts_on_visibility_and_reply_mode"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "terms", force: :cascade do |t|
    t.text "term", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["term"], name: "index_terms_on_term", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "post_terms", "posts"
  add_foreign_key "post_terms", "terms"
  add_foreign_key "posts", "users"
  add_foreign_key "sessions", "users"
end
