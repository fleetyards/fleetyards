# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171027232944) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "uuid-ossp"
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "albums", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "expires"
    t.index ["token"], name: "index_auth_tokens_on_token"
  end

  create_table "components", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "size", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "manufacturer_id"
    t.string "component_class"
    t.string "slug"
  end

  create_table "fleet_memberships", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "fleet_id"
    t.boolean "admin", default: false, null: false
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fleets", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.string "sid"
    t.string "archetype"
    t.string "main_activity"
    t.string "secondary_activity"
    t.boolean "recruiting"
    t.string "commitment"
    t.boolean "rpg"
    t.boolean "exclusive"
    t.integer "member_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hardpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer "quantity"
    t.uuid "model_id"
    t.uuid "component_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "component_class"
    t.string "hardpoint_type"
    t.integer "mounts"
    t.string "size"
    t.string "details"
    t.string "category"
  end

  create_table "images", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.uuid "gallery_id"
    t.string "gallery_type", limit: 255
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "manufacturers", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.string "known_for", limit: 255
    t.text "description"
    t.string "logo", limit: 255
    t.integer "rsi_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "code"
  end

  create_table "model_additions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "length", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "height", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "mass", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "cargo", default: 0, null: false
    t.integer "net_cargo", default: 0, null: false
    t.integer "scm_speed", default: 0, null: false
    t.integer "afterburner_speed", default: 0, null: false
    t.integer "cruise_speed", default: 0, null: false
    t.integer "min_crew", default: 0, null: false
    t.integer "max_crew", default: 0, null: false
  end

  create_table "models", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.text "description"
    t.string "store_image", limit: 255
    t.string "store_url", limit: 255
    t.string "classification", limit: 255
    t.integer "rsi_id"
    t.uuid "manufacturer_id"
    t.uuid "ship_role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "production_status", limit: 255
    t.string "production_note", limit: 255
    t.string "focus", limit: 255
    t.boolean "on_sale", default: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "length", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "height", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "mass", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "cargo", precision: 15, scale: 2, default: "0.0", null: false
    t.string "size"
    t.decimal "scm_speed", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "afterburner_speed", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "cruise_speed", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "min_crew", default: 0, null: false
    t.integer "max_crew", default: 0, null: false
    t.decimal "pitch_max", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "yaw_max", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "roll_max", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "xaxis_acceleration", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "yaxis_acceleration", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "zaxis_acceleration", precision: 15, scale: 2, default: "0.0", null: false
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "gravatar_hash", limit: 255
    t.string "gravatar", limit: 255
    t.string "locale", limit: 255
    t.string "username", limit: 255, default: "", null: false
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 255
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token", limit: 255
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "rsi_handle", limit: 255
    t.boolean "sale_notify", default: true
    t.string "rsi_org"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "model_id"
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "purchased", default: false
    t.boolean "sale_notify", default: true
  end

  create_table "videos", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "url"
    t.integer "video_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "model_id"
  end

end
