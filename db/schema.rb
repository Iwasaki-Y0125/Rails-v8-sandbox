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

ActiveRecord::Schema[8.0].define(version: 2026_01_09_060958) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "terms", force: :cascade do |t|
    t.text "term", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["term"], name: "index_terms_on_term", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "post_terms", "posts"
  add_foreign_key "post_terms", "terms"
  add_foreign_key "posts", "users"
end
