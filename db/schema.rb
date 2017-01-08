# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170108185635) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "uuid-ossp"

  create_table "album_translations", force: true do |t|
    t.uuid     "album_id",    null: false
    t.string   "locale",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "album_translations", ["album_id"], name: "index_album_translations_on_album_id", using: :btree
  add_index "album_translations", ["locale"], name: "index_album_translations_on_locale", using: :btree

  create_table "albums", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.boolean  "enabled",    default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "component_categories", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string "rsi_name"
    t.string "name"
    t.string "slug"
  end

  create_table "component_category_translations", force: true do |t|
    t.uuid     "component_category_id", null: false
    t.string   "locale",                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "component_category_translations", ["component_category_id"], name: "index_component_category_translations_on_component_category_id", using: :btree
  add_index "component_category_translations", ["locale"], name: "index_component_category_translations_on_locale", using: :btree

  create_table "component_translations", force: true do |t|
    t.uuid     "component_id",   null: false
    t.string   "locale",         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "component_type"
  end

  add_index "component_translations", ["component_id"], name: "index_component_translations_on_component_id", using: :btree
  add_index "component_translations", ["locale"], name: "index_component_translations_on_locale", using: :btree

  create_table "components", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.string   "size"
    t.string   "component_type"
    t.boolean  "enabled",        default: false, null: false
    t.integer  "rsi_id"
    t.uuid     "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hardpoint_translations", force: true do |t|
    t.uuid     "hardpoint_id", null: false
    t.string   "locale",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "hardpoint_translations", ["hardpoint_id"], name: "index_hardpoint_translations_on_hardpoint_id", using: :btree
  add_index "hardpoint_translations", ["locale"], name: "index_hardpoint_translations_on_locale", using: :btree

  create_table "hardpoints", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.string   "hardpoint_class"
    t.integer  "rating"
    t.integer  "max_size"
    t.integer  "quantity"
    t.integer  "rsi_id"
    t.uuid     "category_id"
    t.uuid     "ship_id"
    t.uuid     "component_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.uuid     "gallery_id"
    t.string   "gallery_type"
    t.boolean  "enabled",      default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "manufacturer_translations", force: true do |t|
    t.uuid     "manufacturer_id", null: false
    t.string   "locale",          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "manufacturer_translations", ["locale"], name: "index_manufacturer_translations_on_locale", using: :btree
  add_index "manufacturer_translations", ["manufacturer_id"], name: "index_manufacturer_translations_on_manufacturer_id", using: :btree

  create_table "manufacturers", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "known_for"
    t.text     "description"
    t.string   "logo"
    t.boolean  "enabled",     default: false, null: false
    t.integer  "rsi_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ship_role_translations", force: true do |t|
    t.uuid     "ship_role_id", null: false
    t.string   "locale",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "ship_role_translations", ["locale"], name: "index_ship_role_translations_on_locale", using: :btree
  add_index "ship_role_translations", ["ship_role_id"], name: "index_ship_role_translations_on_ship_role_id", using: :btree

  create_table "ship_roles", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ship_translations", force: true do |t|
    t.uuid     "ship_id",     null: false
    t.string   "locale",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "ship_translations", ["locale"], name: "index_ship_translations_on_locale", using: :btree
  add_index "ship_translations", ["ship_id"], name: "index_ship_translations_on_ship_id", using: :btree

  create_table "ships", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.text     "description"
    t.string   "length"
    t.string   "beam"
    t.string   "height"
    t.string   "mass"
    t.string   "cargo"
    t.string   "crew"
    t.string   "store_image"
    t.string   "store_url"
    t.integer  "powerplant_size"
    t.integer  "shield_size"
    t.string   "classification"
    t.boolean  "enabled",           default: false, null: false
    t.integer  "rsi_id"
    t.uuid     "manufacturer_id"
    t.uuid     "ship_role_id"
    t.text     "propulsion_raw"
    t.text     "ordnance_raw"
    t.text     "modular_raw"
    t.text     "avionics_raw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "production_status"
    t.string   "production_note"
    t.string   "focus"
  end

  create_table "user_ships", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.uuid     "user_id"
    t.uuid     "ship_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.boolean  "admin",                   default: false, null: false
    t.hstore   "profile"
    t.hstore   "settings"
    t.string   "gravatar_hash"
    t.string   "gravatar"
    t.string   "locale"
    t.string   "username",                default: "",    null: false
    t.string   "email",                   default: "",    null: false
    t.string   "encrypted_password",      default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",         default: 0,     null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "rsi_organization_url"
    t.string   "rsi_organization_handle"
    t.string   "rsi_organization_name"
    t.string   "rsi_profile_url"
    t.string   "rsi_handle"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "worker_states", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.boolean  "running",        default: false
    t.datetime "last_run_start"
    t.datetime "last_run_end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
