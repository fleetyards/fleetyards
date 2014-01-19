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

ActiveRecord::Schema.define(version: 20140119172741) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "manufacturers", force: true do |t|
    t.string   "name"
    t.string   "rsi_name"
    t.string   "slug"
    t.string   "rsi_slug"
    t.string   "logo"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.boolean  "enabled",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "worker_states", force: true do |t|
    t.string   "name"
    t.boolean  "running",        default: false
    t.datetime "last_run_start"
    t.datetime "last_run_end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
