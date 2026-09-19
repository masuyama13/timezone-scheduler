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

ActiveRecord::Schema[8.1].define(version: 2026_09_19_030944) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "public_token", null: false
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.index ["public_token"], name: "index_events_on_public_token", unique: true
  end

  create_table "responses", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.string "name", null: false
    t.string "time_zone", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_responses_on_event_id"
  end

  create_table "time_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "starts_at"], name: "index_time_options_on_event_id_and_starts_at", unique: true
    t.index ["event_id"], name: "index_time_options_on_event_id"
  end

  create_table "votes", force: :cascade do |t|
    t.boolean "available", null: false
    t.datetime "created_at", null: false
    t.bigint "response_id", null: false
    t.bigint "time_option_id", null: false
    t.datetime "updated_at", null: false
    t.index ["response_id"], name: "index_votes_on_response_id"
    t.index ["time_option_id"], name: "index_votes_on_time_option_id"
  end

  add_foreign_key "responses", "events"
  add_foreign_key "time_options", "events"
  add_foreign_key "votes", "responses"
  add_foreign_key "votes", "time_options"
end
