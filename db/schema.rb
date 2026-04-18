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

ActiveRecord::Schema[8.1].define(version: 2026_04_18_212045) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "consumed_timestep"
    t.datetime "created_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip", limit: 255
    t.string "normalized_email"
    t.string "normalized_username"
    t.string "otp_backup_codes", array: true
    t.boolean "otp_required_for_login"
    t.string "otp_secret"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token", limit: 255
    t.string "resource_access"
    t.integer "sign_in_count", default: 0, null: false
    t.boolean "super_admin", default: false
    t.datetime "updated_at", precision: nil
    t.string "username", limit: 255, default: "", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_admin_users_on_username", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time", precision: nil
    t.uuid "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["time"], name: "index_ahoy_events_on_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "accept_language"
    t.string "browser"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.string "os"
    t.text "referrer"
    t.string "referring_domain"
    t.datetime "started_at", precision: nil
    t.text "user_agent"
    t.uuid "user_id"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "albums", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.boolean "enabled", default: false, null: false
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.datetime "updated_at", precision: nil
  end

  create_table "cargo_hold_container_capacities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "best_orientation"
    t.uuid "cargo_hold_id", null: false
    t.integer "container_size_scu", null: false
    t.datetime "created_at", null: false
    t.integer "max_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["cargo_hold_id", "container_size_scu"], name: "index_cargo_hold_capacities_on_hold_and_size", unique: true
    t.index ["container_size_scu"], name: "index_cargo_hold_container_capacities_on_container_size_scu"
    t.index ["max_quantity"], name: "index_cargo_hold_container_capacities_on_max_quantity"
  end

  create_table "cargo_holds", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "capacity_scu", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "dimension_x", precision: 15, scale: 2, null: false
    t.decimal "dimension_y", precision: 15, scale: 2, null: false
    t.decimal "dimension_z", precision: 15, scale: 2, null: false
    t.decimal "max_container_dimension_x", precision: 15, scale: 2
    t.decimal "max_container_dimension_y", precision: 15, scale: 2
    t.decimal "max_container_dimension_z", precision: 15, scale: 2
    t.integer "max_container_size_scu", null: false
    t.decimal "min_container_dimension_x", precision: 15, scale: 2
    t.decimal "min_container_dimension_y", precision: 15, scale: 2
    t.decimal "min_container_dimension_z", precision: 15, scale: 2
    t.integer "min_container_size_scu"
    t.uuid "model_id", null: false
    t.string "name"
    t.decimal "offset_x", precision: 15, scale: 2
    t.decimal "offset_y", precision: 15, scale: 2
    t.decimal "offset_z", precision: 15, scale: 2
    t.integer "position"
    t.integer "rotation"
    t.datetime "updated_at", null: false
    t.index ["capacity_scu"], name: "index_cargo_holds_on_capacity_scu"
    t.index ["model_id", "max_container_size_scu"], name: "index_cargo_holds_on_model_id_and_max_container_size_scu"
  end

  create_table "components", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "ammunition"
    t.string "category"
    t.string "component_class"
    t.string "component_sub_type"
    t.string "component_type"
    t.datetime "created_at", precision: nil
    t.text "description"
    t.string "durability"
    t.string "grade"
    t.string "heat_connection"
    t.boolean "hidden", default: false
    t.string "inventory_consumption"
    t.integer "item_class"
    t.string "item_type"
    t.uuid "manufacturer_id"
    t.string "name", limit: 255
    t.string "power_connection"
    t.string "sc_key"
    t.string "sc_ref"
    t.string "size", limit: 255
    t.string "slug"
    t.integer "tracking_signal"
    t.string "type_data"
    t.datetime "updated_at", precision: nil
    t.string "version"
    t.index ["manufacturer_id"], name: "index_components_on_manufacturer_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "docks", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "beam", precision: 15, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.integer "dock_type"
    t.string "group"
    t.decimal "height", precision: 15, scale: 2
    t.decimal "length", precision: 15, scale: 2
    t.integer "max_ship_size"
    t.integer "min_ship_size"
    t.uuid "model_id"
    t.string "name"
    t.integer "ship_size"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "email_rejections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
  end

  create_table "equipment", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "backpack_compatibility"
    t.integer "core_compatibility"
    t.datetime "created_at", precision: nil, null: false
    t.decimal "damage_reduction", precision: 15, scale: 2
    t.text "description"
    t.integer "equipment_type"
    t.string "extras"
    t.string "grade"
    t.boolean "hidden", default: true
    t.integer "item_type"
    t.uuid "manufacturer_id"
    t.string "name"
    t.decimal "range", precision: 15, scale: 2
    t.decimal "rate_of_fire", precision: 15, scale: 2
    t.string "size"
    t.integer "slot"
    t.string "slug"
    t.decimal "storage", precision: 15, scale: 2
    t.string "store_image"
    t.integer "store_image_height"
    t.integer "store_image_width"
    t.string "temperature_rating"
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "volume", precision: 15, scale: 2
    t.integer "weapon_class"
    t.index ["manufacturer_id"], name: "index_equipment_on_manufacturer_id"
  end

  create_table "feature_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_name", null: false
    t.boolean "self_service", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["feature_name"], name: "index_feature_settings_on_feature_name", unique: true
  end

  create_table "fleet_invite_urls", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_after", precision: nil
    t.uuid "fleet_id"
    t.integer "limit"
    t.string "token"
    t.datetime "updated_at", null: false
    t.integer "usage_count", default: 0, null: false
    t.uuid "user_id"
    t.index ["token"], name: "index_fleet_invite_urls_on_token", unique: true
  end

  create_table "fleet_memberships", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "aasm_state"
    t.datetime "accepted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "declined_at", precision: nil
    t.uuid "fleet_id"
    t.uuid "fleet_role_id"
    t.uuid "hangar_group_id"
    t.boolean "hide_ships", default: false
    t.datetime "invited_at", precision: nil
    t.uuid "invited_by"
    t.boolean "primary", default: false
    t.datetime "requested_at", precision: nil
    t.integer "ships_filter", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.string "used_invite_token"
    t.uuid "user_id"
    t.index ["fleet_role_id"], name: "index_fleet_memberships_on_fleet_role_id"
    t.index ["user_id", "fleet_id"], name: "index_fleet_memberships_on_user_id_and_fleet_id", unique: true
  end

  create_table "fleet_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "fleet_id", null: false
    t.string "name"
    t.boolean "permanent"
    t.text "rank"
    t.text "resource_access"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["fleet_id", "rank"], name: "index_fleet_roles_on_fleet_id_and_rank", unique: true
  end

  create_table "fleet_vehicles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "fleet_id"
    t.datetime "updated_at", null: false
    t.uuid "vehicle_id"
    t.index ["fleet_id", "vehicle_id"], name: "index_fleet_vehicles_on_fleet_id_and_vehicle_id", unique: true
    t.index ["vehicle_id"], name: "index_fleet_vehicles_on_vehicle_id"
  end

  create_table "fleets", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "created_by"
    t.text "description"
    t.string "discord"
    t.string "fid"
    t.string "guilded"
    t.string "homepage"
    t.string "name"
    t.string "normalized_fid"
    t.boolean "public_fleet", default: false
    t.boolean "public_fleet_stats", default: false
    t.string "rsi_sid"
    t.string "sid"
    t.string "slug"
    t.string "ts"
    t.string "twitch"
    t.datetime "updated_at", precision: nil, null: false
    t.string "youtube"
    t.index ["fid"], name: "index_fleets_on_fid", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "github_issue_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content_digest", null: false
    t.datetime "created_at", null: false
    t.integer "issue_number"
    t.string "task_type", null: false
    t.datetime "updated_at", null: false
    t.index ["task_type"], name: "index_github_issue_logs_on_task_type"
  end

  create_table "hangar_groups", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.boolean "public", default: false
    t.string "slug"
    t.integer "sort"
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "user_id"
    t.index ["user_id", "name"], name: "index_hangar_groups_on_user_id_and_name", unique: true
  end

  create_table "hardpoints", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category"
    t.uuid "component_id"
    t.datetime "created_at", null: false
    t.string "details"
    t.integer "group"
    t.string "group_key"
    t.string "matrix_key"
    t.integer "max_size"
    t.integer "min_size"
    t.uuid "parent_id", null: false
    t.string "parent_type", null: false
    t.string "sc_name"
    t.integer "source"
    t.string "types"
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_hardpoints_on_component_id"
    t.index ["parent_type", "parent_id"], name: "index_hardpoints_on_parent"
  end

  create_table "images", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "background", default: true
    t.string "caption"
    t.datetime "created_at", precision: nil
    t.boolean "enabled", default: false, null: false
    t.uuid "gallery_id"
    t.string "gallery_name"
    t.string "gallery_slug"
    t.string "gallery_type", limit: 255
    t.boolean "global", default: true
    t.datetime "updated_at", precision: nil
    t.index ["gallery_id"], name: "index_images_on_gallery_id"
  end

  create_table "imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "failed_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.text "import_data"
    t.text "info"
    t.jsonb "input"
    t.jsonb "output"
    t.datetime "started_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "version"
    t.index ["aasm_state", "type"], name: "index_imports_on_aasm_state_and_type"
    t.index ["type"], name: "index_imports_on_type"
  end

  create_table "item_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.string "location"
    t.string "location_url"
    t.decimal "price", precision: 15, scale: 2
    t.integer "price_type"
    t.integer "time_range"
    t.datetime "updated_at", null: false
    t.index ["item_type", "item_id"], name: "index_item_prices_on_item"
  end

  create_table "maintenance_tasks_runs", force: :cascade do |t|
    t.text "arguments"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.string "cursor"
    t.datetime "ended_at", precision: nil
    t.string "error_class"
    t.string "error_message"
    t.string "job_id"
    t.integer "lock_version", default: 0, null: false
    t.text "metadata"
    t.datetime "started_at", precision: nil
    t.string "status", default: "enqueued", null: false
    t.string "task_name", null: false
    t.bigint "tick_count", default: 0, null: false
    t.bigint "tick_total"
    t.float "time_running", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["task_name", "status", "created_at"], name: "index_maintenance_tasks_runs", order: { created_at: :desc }
  end

  create_table "manufacturers", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.string "code_mapping"
    t.datetime "created_at", precision: nil
    t.text "description"
    t.string "known_for", limit: 255
    t.string "long_name"
    t.string "name", limit: 255
    t.integer "rsi_id"
    t.string "sc_ref"
    t.string "slug", limit: 255
    t.datetime "updated_at", precision: nil
  end

  create_table "message_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "message_id"
    t.binary "payload"
    t.datetime "updated_at", null: false
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "archived", default: false
    t.text "body"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "from"
    t.text "from_raw"
    t.boolean "read", default: false
    t.string "subject"
    t.text "to"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
  end

  create_table "model_hardpoint_loadouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "component_id"
    t.datetime "created_at", null: false
    t.uuid "model_hardpoint_id"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "model_hardpoints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category"
    t.uuid "component_id"
    t.datetime "created_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "details"
    t.integer "group"
    t.integer "hardpoint_type"
    t.integer "item_slot"
    t.integer "item_slots"
    t.string "key"
    t.string "loadout_identifier"
    t.uuid "model_id"
    t.string "mount"
    t.string "name"
    t.integer "size"
    t.integer "source"
    t.integer "sub_category"
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_model_hardpoints_on_component_id"
    t.index ["model_id"], name: "index_model_hardpoints_on_model_id"
  end

  create_table "model_loaners", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false
    t.uuid "loaner_model_id"
    t.uuid "model_id"
    t.datetime "updated_at", null: false
  end

  create_table "model_module_package_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "model_module_id"
    t.uuid "model_module_package_id"
    t.datetime "updated_at", null: false
  end

  create_table "model_module_packages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "hidden", default: true
    t.uuid "model_id"
    t.string "name"
    t.decimal "pledge_price", precision: 15, scale: 2
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "model_modules", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.decimal "cargo", precision: 15, scale: 2
    t.string "cargo_holds"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.boolean "hidden", default: true
    t.uuid "manufacturer_id"
    t.uuid "model_id"
    t.string "name"
    t.decimal "pledge_price", precision: 15, scale: 2
    t.string "production_status"
    t.string "sc_key"
    t.string "slug"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "model_paints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "hidden", default: true
    t.datetime "last_updated_at", precision: nil
    t.uuid "model_id"
    t.string "name"
    t.boolean "on_sale", default: false
    t.decimal "pledge_price", precision: 15, scale: 2
    t.string "production_note"
    t.string "production_status"
    t.string "rsi_description"
    t.integer "rsi_id"
    t.string "rsi_name"
    t.string "rsi_slug"
    t.string "rsi_store_url"
    t.string "slug"
    t.datetime "store_images_updated_at", precision: nil
    t.string "store_url"
    t.datetime "updated_at", null: false
  end

  create_table "model_snub_crafts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "model_id", null: false
    t.uuid "snub_craft_id", null: false
    t.datetime "updated_at", null: false
  end

  create_table "model_upgrades", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.boolean "hidden", default: true
    t.string "name"
    t.decimal "pledge_price", precision: 15, scale: 2
    t.string "slug"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "models", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.boolean "adi_map", default: false
    t.uuid "base_model_id"
    t.decimal "beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "cargo", precision: 15, scale: 2
    t.string "cargo_holds"
    t.string "classification", limit: 255
    t.datetime "created_at", precision: nil
    t.text "description"
    t.integer "dock_size"
    t.string "erkul_identifier"
    t.decimal "fleetchart_offset_beam", precision: 15, scale: 2
    t.decimal "fleetchart_offset_length", precision: 15, scale: 2
    t.string "focus", limit: 255
    t.decimal "fuel_consumption", precision: 15, scale: 2
    t.boolean "ground", default: false
    t.decimal "ground_acceleration", precision: 15, scale: 2
    t.decimal "ground_decceleration", precision: 15, scale: 2
    t.decimal "ground_max_speed", precision: 15, scale: 2
    t.decimal "ground_reverse_speed", precision: 15, scale: 2
    t.decimal "height", precision: 15, scale: 2, default: "0.0", null: false
    t.boolean "hidden", default: true
    t.boolean "holo_colored", default: false
    t.decimal "hydrogen_fuel_tank_size", precision: 15, scale: 2
    t.string "hydrogen_fuel_tanks"
    t.integer "images_count", default: 0
    t.boolean "in_game", default: false, null: false
    t.datetime "last_updated_at", precision: nil
    t.string "legacy_slug"
    t.decimal "length", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "loaners_count", default: 0, null: false
    t.uuid "manufacturer_id"
    t.decimal "mass", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "max_crew"
    t.decimal "max_speed", precision: 15, scale: 2
    t.decimal "max_speed_acceleration", precision: 15, scale: 2
    t.decimal "max_speed_decceleration", precision: 15, scale: 2
    t.integer "min_crew"
    t.integer "model_paints_count", default: 0
    t.integer "module_hardpoints_count", default: 0
    t.string "name", limit: 255
    t.boolean "notified", default: false
    t.boolean "on_sale", default: false
    t.decimal "pitch", precision: 15, scale: 2
    t.decimal "pitch_boosted", precision: 15, scale: 2
    t.decimal "pledge_price", precision: 15, scale: 2
    t.decimal "price", precision: 15, scale: 2
    t.string "production_note", limit: 255
    t.string "production_status", limit: 255
    t.decimal "quantum_fuel_tank_size", precision: 15, scale: 2
    t.string "quantum_fuel_tanks"
    t.decimal "reverse_speed_boosted", precision: 15, scale: 2
    t.decimal "roll", precision: 15, scale: 2
    t.decimal "roll_boosted", precision: 15, scale: 2
    t.decimal "rsi_beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "rsi_cargo", precision: 15, scale: 2
    t.integer "rsi_chassis_id"
    t.string "rsi_classification"
    t.string "rsi_ctm_url"
    t.text "rsi_description"
    t.string "rsi_focus"
    t.decimal "rsi_height", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "rsi_id"
    t.decimal "rsi_length", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "rsi_mass", precision: 15, scale: 2, default: "0.0", null: false
    t.integer "rsi_max_crew"
    t.decimal "rsi_max_speed", precision: 15, scale: 2
    t.integer "rsi_min_crew"
    t.string "rsi_name"
    t.decimal "rsi_pitch", precision: 15, scale: 2
    t.string "rsi_pledge_slug"
    t.integer "rsi_pledge_value"
    t.decimal "rsi_roll", precision: 15, scale: 2
    t.decimal "rsi_scm_speed", precision: 15, scale: 2
    t.string "rsi_size"
    t.string "rsi_slug"
    t.string "rsi_store_url"
    t.decimal "rsi_yaw", precision: 15, scale: 2
    t.string "sales_page_url"
    t.decimal "sc_beam", precision: 15, scale: 2
    t.decimal "sc_height", precision: 15, scale: 2
    t.decimal "sc_length", precision: 15, scale: 2
    t.decimal "scm_speed", precision: 15, scale: 2
    t.decimal "scm_speed_acceleration", precision: 15, scale: 2
    t.decimal "scm_speed_boosted", precision: 15, scale: 2
    t.decimal "scm_speed_decceleration", precision: 15, scale: 2
    t.string "size"
    t.string "slug", limit: 255
    t.datetime "store_images_updated_at", precision: nil
    t.string "store_url", limit: 255
    t.datetime "updated_at", precision: nil
    t.integer "upgrade_kits_count", default: 0
    t.integer "videos_count", default: 0
    t.decimal "yaw", precision: 15, scale: 2
    t.decimal "yaw_boosted", precision: 15, scale: 2
    t.index ["base_model_id"], name: "index_models_on_base_model_id"
    t.index ["classification"], name: "index_models_on_classification"
    t.index ["legacy_slug"], name: "index_models_on_legacy_slug"
    t.index ["manufacturer_id", "name"], name: "index_models_on_manufacturer_id_and_name", unique: true
    t.index ["manufacturer_id"], name: "index_models_on_manufacturer_id"
    t.index ["production_status"], name: "index_models_on_production_status"
    t.index ["size"], name: "index_models_on_size"
  end

  create_table "module_hardpoints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "model_id"
    t.uuid "model_module_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "notification_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "app", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "mail", default: false, null: false
    t.string "notification_type", null: false
    t.boolean "push", default: false, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "notification_type"], name: "idx_on_user_id_notification_type_2ab4363e9b", unique: true
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "icon"
    t.string "link"
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.uuid "record_id"
    t.string "record_type"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["expires_at"], name: "index_notifications_on_expires_at"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["record_type", "record_id"], name: "index_notifications_on_record"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at", order: { created_at: :desc }
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
  end

  create_table "oauth_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.uuid "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", limit: 512, null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.text "refresh_token"
    t.uuid "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.text "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "owner_id"
    t.string "owner_type"
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.string "secret", limit: 512, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "omniauth_connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "auth_payload"
    t.datetime "created_at", null: false
    t.integer "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_omniauth_connections_on_user_id"
  end

  create_table "rollups", force: :cascade do |t|
    t.jsonb "dimensions", default: {}, null: false
    t.string "interval", null: false
    t.string "name", null: false
    t.datetime "time", precision: nil, null: false
    t.float "value"
    t.index ["name", "interval", "time", "dimensions"], name: "index_rollups_on_name_and_interval_and_time_and_dimensions", unique: true
  end

  create_table "rsi_request_logs", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "resolved", default: false
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "star_citizen_updates", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "news_sub_type"
    t.string "news_type"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "task_forces", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "hangar_group_id"
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "vehicle_id"
    t.index ["hangar_group_id"], name: "index_task_forces_on_hangar_group_id"
    t.index ["vehicle_id"], name: "index_task_forces_on_vehicle_id"
  end

  create_table "upgrade_kits", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "model_id"
    t.uuid "model_upgrade_id"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.integer "consumed_timestep"
    t.datetime "created_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "current_system"
    t.string "current_system_code"
    t.string "discord"
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "guilded"
    t.datetime "hangar_updated_at", precision: nil
    t.boolean "hide_owner", default: false, null: false
    t.string "homepage"
    t.datetime "last_active_at"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip", limit: 255
    t.decimal "latitude", precision: 10, scale: 6
    t.string "locale", limit: 255
    t.string "location"
    t.datetime "locked_at", precision: nil
    t.decimal "longitude", precision: 10, scale: 6
    t.string "normalized_email"
    t.string "normalized_username"
    t.string "otp_backup_codes", array: true
    t.boolean "otp_required_for_login"
    t.string "otp_secret"
    t.boolean "password_set_manually", default: false, null: false
    t.boolean "public_hangar", default: true
    t.boolean "public_hangar_loaners", default: false
    t.boolean "public_hangar_stats", default: false
    t.boolean "public_wishlist", default: false
    t.integer "purchased_vehicles_count", default: 0, null: false
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token", limit: 255
    t.string "rsi_handle"
    t.boolean "sale_notify", default: false
    t.integer "sign_in_count", default: 0, null: false
    t.boolean "tester", default: false
    t.boolean "tracking", default: true
    t.string "twitch"
    t.string "unconfirmed_email", limit: 255
    t.string "unlock_token", limit: 255
    t.datetime "updated_at", precision: nil
    t.string "username", limit: 255, default: "", null: false
    t.integer "wanted_vehicles_count", default: 0, null: false
    t.string "youtube"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["normalized_username"], name: "index_users_on_normalized_username"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicle_modules", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "model_module_id"
    t.string "rsi_pledge_id"
    t.datetime "rsi_pledge_synced_at"
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "vehicle_id"
  end

  create_table "vehicle_upgrades", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "model_upgrade_id"
    t.string "rsi_pledge_id"
    t.datetime "rsi_pledge_synced_at"
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "vehicle_id"
  end

  create_table "vehicles", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "alternative_names"
    t.integer "bought_via", default: 0
    t.datetime "created_at", precision: nil
    t.boolean "flagship", default: false
    t.boolean "hidden", default: false
    t.boolean "loaner", default: false
    t.uuid "model_id"
    t.uuid "model_paint_id"
    t.uuid "module_package_id"
    t.string "name", limit: 255
    t.boolean "name_visible", default: false
    t.boolean "notify", default: true
    t.boolean "public", default: false
    t.string "rsi_pledge_id"
    t.datetime "rsi_pledge_synced_at"
    t.boolean "sale_notify", default: false
    t.string "serial"
    t.string "slug"
    t.datetime "updated_at", precision: nil
    t.uuid "user_id"
    t.uuid "vehicle_id"
    t.boolean "wanted", default: false
    t.index ["hidden", "loaner"], name: "index_vehicles_on_hidden_and_loaner"
    t.index ["model_id", "id"], name: "index_vehicles_on_model_id_and_id"
    t.index ["serial", "user_id"], name: "index_vehicles_on_serial_and_user_id", unique: true
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end

  create_table "versions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id"
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.json "object"
    t.json "object_changes"
    t.text "old_object"
    t.text "old_object_changes"
    t.string "reason"
    t.text "reason_description"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "videos", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "model_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.integer "video_type"
    t.index ["model_id"], name: "index_videos_on_model_id"
  end

  create_table "youtube_updates", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "video_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cargo_hold_container_capacities", "cargo_holds"
  add_foreign_key "cargo_holds", "models"
  add_foreign_key "fleet_memberships", "fleet_roles"
  add_foreign_key "fleet_roles", "fleets"
  add_foreign_key "hardpoints", "components"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "omniauth_connections", "users"
end
