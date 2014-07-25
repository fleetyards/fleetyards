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

ActiveRecord::Schema.define(version: 20140129225911) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "album_translations", force: true do |t|
    t.integer  "album_id",    null: false
    t.string   "locale",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "album_translations", ["album_id"], name: "index_album_translations_on_album_id", using: :btree
  add_index "album_translations", ["locale"], name: "index_album_translations_on_locale", using: :btree

  create_table "albums", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.boolean  "enabled",    default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equipment", force: true do |t|
    t.string   "name"
    t.string   "equipment_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",        default: false, null: false
  end

  create_table "equipment_ships", id: false, force: true do |t|
    t.integer "equipment_id"
    t.integer "ship_id"
  end

  create_table "equipment_translations", force: true do |t|
    t.integer  "equipment_id", null: false
    t.string   "locale",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "equipment_translations", ["equipment_id"], name: "index_equipment_translations_on_equipment_id", using: :btree
  add_index "equipment_translations", ["locale"], name: "index_equipment_translations_on_locale", using: :btree

  create_table "hardpoint_translations", force: true do |t|
    t.integer  "hardpoint_id", null: false
    t.string   "locale",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "hardpoint_translations", ["hardpoint_id"], name: "index_hardpoint_translations_on_hardpoint_id", using: :btree
  add_index "hardpoint_translations", ["locale"], name: "index_hardpoint_translations_on_locale", using: :btree

  create_table "hardpoints", force: true do |t|
    t.integer  "weapon_id"
    t.integer  "ship_id"
    t.text     "description"
    t.string   "hp_class"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: true do |t|
    t.string   "name"
    t.integer  "gallery_id"
    t.string   "gallery_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",      default: false, null: false
  end

  create_table "manufacturers", force: true do |t|
    t.string   "name"
    t.string   "rsi_name"
    t.string   "slug"
    t.string   "rsi_slug"
    t.string   "logo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",    default: false, null: false
  end

  create_table "settings", force: true do |t|
    t.string   "keypath"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ship_roles", force: true do |t|
    t.string   "name"
    t.string   "rsi_name"
    t.string   "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ship_translations", force: true do |t|
    t.integer  "ship_id",     null: false
    t.string   "locale",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "ship_translations", ["locale"], name: "index_ship_translations_on_locale", using: :btree
  add_index "ship_translations", ["ship_id"], name: "index_ship_translations_on_ship_id", using: :btree

  create_table "ships", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "rsi_name"
    t.integer  "manufacturer_id"
    t.integer  "ship_role_id"
    t.text     "description"
    t.string   "length"
    t.string   "beam"
    t.string   "height"
    t.string   "mass"
    t.string   "cargo"
    t.string   "crew"
    t.string   "image"
    t.boolean  "enabled",                    default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base"
    t.string   "basename"
    t.string   "store_url"
    t.integer  "max_upgrades"
    t.text     "max_equipment_raw"
    t.text     "factory_equipment_raw"
    t.text     "weapons_raw"
    t.integer  "max_class1"
    t.integer  "max_class2"
    t.integer  "max_class3"
    t.integer  "max_class4"
    t.integer  "max_class5"
    t.integer  "max_class6"
    t.integer  "max_class7"
    t.integer  "max_class8"
    t.integer  "max_powerplant"
    t.string   "max_powerplant_type"
    t.integer  "max_thrusters"
    t.string   "max_thrusters_type"
    t.integer  "max_primary_thrusters"
    t.string   "max_primary_thrusters_type"
    t.integer  "max_shield"
    t.string   "max_shield_type"
    t.boolean  "is_base",                    default: false, null: false
  end

  create_table "users", force: true do |t|
    t.boolean  "admin",                  default: false, null: false
    t.hstore   "profile"
    t.hstore   "settings"
    t.string   "gravatar_hash"
    t.string   "gravatar"
    t.string   "username",               default: "",    null: false
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,     null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "weapon_translations", force: true do |t|
    t.integer  "weapon_id",   null: false
    t.string   "locale",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "weapon_translations", ["locale"], name: "index_weapon_translations_on_locale", using: :btree
  add_index "weapon_translations", ["weapon_id"], name: "index_weapon_translations_on_weapon_id", using: :btree

  create_table "weapons", force: true do |t|
    t.string   "name"
    t.string   "hp_class"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",    default: false, null: false
  end

  create_table "worker_states", force: true do |t|
    t.string   "name"
    t.boolean  "running",        default: false
    t.datetime "last_run_start"
    t.datetime "last_run_end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
