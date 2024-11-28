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

ActiveRecord::Schema[7.1].define(version: 2024_11_27_134349) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "admin_users", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "username", limit: 255, default: "", null: false
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.string "otp_secret"
    t.string "normalized_username"
    t.string "normalized_email"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_admin_users_on_username", unique: true
  end

  create_table "affiliations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "affiliationable_type"
    t.uuid "affiliationable_id"
    t.uuid "faction_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["affiliationable_type", "affiliationable_id"], name: "index_affiliations_on_affiliationable"
    t.index ["faction_id"], name: "index_affiliations_on_faction_id"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.uuid "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time", precision: nil
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["time"], name: "index_ahoy_events_on_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.uuid "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.datetime "started_at", precision: nil
    t.string "accept_language"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "albums", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "audits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "auditable_id"
    t.string "auditable_type"
    t.uuid "associated_id"
    t.string "associated_type"
    t.uuid "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "celestial_objects", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.uuid "starsystem_id"
    t.string "object_type"
    t.integer "rsi_id"
    t.string "code"
    t.string "status"
    t.string "designation"
    t.datetime "last_updated_at", precision: nil
    t.text "description"
    t.boolean "hidden", default: true
    t.string "orbit_period"
    t.boolean "habitable", default: false
    t.boolean "fairchanceact", default: false
    t.integer "sensor_population"
    t.integer "sensor_economy"
    t.integer "sensor_danger"
    t.string "size"
    t.string "sub_type"
    t.string "store_image"
    t.uuid "parent_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["starsystem_id"], name: "index_celestial_objects_on_starsystem_id"
  end

  create_table "commodities", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "description"
    t.string "store_image"
    t.integer "commodity_type"
    t.index ["name"], name: "index_commodities_on_name", unique: true
  end

  create_table "commodity_prices", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.uuid "shop_commodity_id"
    t.decimal "price", precision: 15, scale: 2
    t.integer "time_range"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confirmed", default: false
    t.integer "submission_count", default: 0
    t.string "submitters"
    t.index ["shop_commodity_id"], name: "index_commodity_prices_on_shop_commodity_id"
  end

  create_table "components", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "size", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.uuid "manufacturer_id"
    t.string "component_class"
    t.string "slug"
    t.string "item_type"
    t.text "description"
    t.string "store_image"
    t.string "grade"
    t.integer "item_class"
    t.integer "tracking_signal"
    t.string "sc_identifier"
    t.string "type_data"
    t.string "durability"
    t.string "power_connection"
    t.string "heat_connection"
    t.string "ammunition"
    t.boolean "hidden", default: false
    t.string "sc_key"
    t.string "sc_ref"
    t.string "category"
    t.string "component_type"
    t.string "component_sub_type"
    t.string "inventory_consumption"
    t.index ["manufacturer_id"], name: "index_components_on_manufacturer_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "docks", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "dock_type"
    t.uuid "station_id"
    t.string "name"
    t.integer "max_ship_size"
    t.integer "min_ship_size"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "ship_size"
    t.uuid "model_id"
    t.decimal "height", precision: 15, scale: 2
    t.decimal "beam", precision: 15, scale: 2
    t.decimal "length", precision: 15, scale: 2
    t.string "group"
    t.index ["station_id"], name: "index_docks_on_station_id"
  end

  create_table "email_rejections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "equipment", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "store_image"
    t.integer "equipment_type"
    t.boolean "hidden", default: true
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "manufacturer_id"
    t.integer "item_type"
    t.string "size"
    t.string "grade"
    t.decimal "damage_reduction", precision: 15, scale: 2
    t.decimal "rate_of_fire", precision: 15, scale: 2
    t.decimal "range", precision: 15, scale: 2
    t.string "extras"
    t.integer "weapon_class"
    t.integer "slot"
    t.decimal "storage", precision: 15, scale: 2
    t.decimal "volume", precision: 15, scale: 2
    t.string "temperature_rating"
    t.integer "backpack_compatibility"
    t.integer "core_compatibility"
    t.index ["manufacturer_id"], name: "index_equipment_on_manufacturer_id"
  end

  create_table "factions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rsi_id"
    t.string "name"
    t.string "slug"
    t.string "code"
    t.string "color"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "fleet_invite_urls", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "fleet_id"
    t.uuid "user_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_after", precision: nil
    t.integer "limit"
    t.index ["token"], name: "index_fleet_invite_urls_on_token", unique: true
  end

  create_table "fleet_memberships", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "fleet_id"
    t.uuid "user_id"
    t.integer "role"
    t.datetime "accepted_at", precision: nil
    t.datetime "declined_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "primary", default: false
    t.boolean "hide_ships", default: false
    t.integer "ships_filter", default: 0
    t.uuid "hangar_group_id"
    t.uuid "invited_by"
    t.string "aasm_state"
    t.datetime "invited_at", precision: nil
    t.datetime "requested_at", precision: nil
    t.string "used_invite_token"
    t.index ["user_id", "fleet_id"], name: "index_fleet_memberships_on_user_id_and_fleet_id", unique: true
  end

  create_table "fleet_vehicles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "vehicle_id"
    t.uuid "fleet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fleet_id", "vehicle_id"], name: "index_fleet_vehicles_on_fleet_id_and_vehicle_id", unique: true
    t.index ["vehicle_id"], name: "index_fleet_vehicles_on_vehicle_id"
  end

  create_table "fleets", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "fid"
    t.string "slug"
    t.string "sid"
    t.string "logo"
    t.string "background_image"
    t.uuid "created_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.string "discord"
    t.string "rsi_sid"
    t.string "twitch"
    t.string "youtube"
    t.string "ts"
    t.string "homepage"
    t.string "guilded"
    t.boolean "public_fleet", default: false
    t.text "description"
    t.boolean "public_fleet_stats", default: false
    t.index ["fid"], name: "index_fleets_on_fid", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "habitations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "habitation_type"
    t.uuid "station_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "habitation_name"
    t.index ["station_id"], name: "index_habitations_on_station_id"
  end

  create_table "hangar_groups", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "color"
    t.uuid "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sort"
    t.boolean "public", default: false
    t.index ["user_id", "name"], name: "index_hangar_groups_on_user_id_and_name", unique: true
  end

  create_table "hardpoints", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "sc_name"
    t.integer "min_size"
    t.integer "max_size"
    t.string "types"
    t.string "parent_type", null: false
    t.uuid "parent_id", null: false
    t.uuid "component_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "source"
    t.integer "group"
    t.index ["component_id"], name: "index_hardpoints_on_component_id"
    t.index ["parent_type", "parent_id"], name: "index_hardpoints_on_parent"
  end

  create_table "images", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.uuid "gallery_id"
    t.string "gallery_type", limit: 255
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "background", default: true
    t.integer "width"
    t.integer "height"
    t.boolean "global", default: true
    t.string "caption"
    t.index ["gallery_id"], name: "index_images_on_gallery_id"
  end

  create_table "imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.string "version"
    t.datetime "started_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "aasm_state"
    t.text "info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "input"
    t.jsonb "output"
    t.uuid "user_id"
    t.string "import"
    t.text "import_data"
  end

  create_table "item_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "price_type"
    t.decimal "price", precision: 15, scale: 2
    t.string "location"
    t.string "location_url"
    t.integer "time_range"
    t.string "item_type", null: false
    t.uuid "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_type", "item_id"], name: "index_item_prices_on_item"
  end

  create_table "manufacturers", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.string "known_for", limit: 255
    t.text "description"
    t.string "logo", limit: 255
    t.integer "rsi_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "code"
    t.string "long_name"
    t.string "code_mapping"
    t.string "sc_ref"
  end

  create_table "message_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.binary "payload"
    t.uuid "message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "from"
    t.uuid "user_id"
    t.string "subject"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "read", default: false
    t.boolean "archived", default: false
    t.string "email"
    t.text "to"
    t.text "from_raw"
  end

  create_table "model_additions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "length", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "height", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "mass", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "cargo", precision: 15, scale: 2
    t.decimal "net_cargo", precision: 15, scale: 2
    t.decimal "scm_speed", precision: 15, scale: 2
    t.decimal "afterburner_speed", precision: 15, scale: 2
    t.decimal "cruise_speed", precision: 15, scale: 2
    t.integer "min_crew"
    t.integer "max_crew"
    t.decimal "price", precision: 15, scale: 2
    t.index ["model_id"], name: "index_model_additions_on_model_id"
  end

  create_table "model_hardpoint_loadouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "component_id"
    t.uuid "model_hardpoint_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "model_hardpoints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "size"
    t.integer "source"
    t.string "key"
    t.integer "hardpoint_type"
    t.integer "category"
    t.integer "group"
    t.uuid "model_id"
    t.uuid "component_id"
    t.datetime "deleted_at", precision: nil
    t.string "details"
    t.string "mount"
    t.integer "item_slots"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "loadout_identifier"
    t.integer "item_slot"
    t.integer "sub_category"
    t.index ["component_id"], name: "index_model_hardpoints_on_component_id"
    t.index ["model_id"], name: "index_model_hardpoints_on_model_id"
  end

  create_table "model_loaners", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_id"
    t.uuid "loaner_model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false
  end

  create_table "model_module_package_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_module_package_id"
    t.uuid "model_module_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "model_module_packages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_id"
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "store_image"
    t.boolean "hidden", default: true
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "pledge_price", precision: 15, scale: 2
    t.string "angled_view"
    t.integer "angled_view_height"
    t.integer "angled_view_width"
    t.string "top_view"
    t.integer "top_view_height"
    t.integer "top_view_width"
    t.string "side_view"
    t.integer "side_view_height"
    t.integer "side_view_width"
  end

  create_table "model_modules", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.uuid "manufacturer_id"
    t.uuid "model_id"
    t.boolean "active", default: true
    t.boolean "hidden", default: true
    t.string "production_status"
    t.string "store_image"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "pledge_price", precision: 15, scale: 2
    t.string "sc_key"
    t.decimal "cargo", precision: 15, scale: 2
    t.string "cargo_holds"
  end

  create_table "model_paints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.uuid "model_id"
    t.string "slug"
    t.string "description"
    t.decimal "pledge_price", precision: 15, scale: 2
    t.decimal "last_pledge_price", precision: 15, scale: 2
    t.string "store_image"
    t.boolean "active", default: true
    t.boolean "hidden", default: true
    t.datetime "store_images_updated_at", precision: nil
    t.string "store_url"
    t.integer "rsi_id"
    t.string "rsi_name"
    t.string "rsi_slug"
    t.string "rsi_description"
    t.string "rsi_store_url"
    t.datetime "last_updated_at", precision: nil
    t.boolean "on_sale", default: false
    t.string "production_status"
    t.string "production_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rsi_store_image"
    t.string "fleetchart_image"
    t.string "top_view"
    t.string "side_view"
    t.string "angled_view"
    t.integer "fleetchart_image_height"
    t.integer "fleetchart_image_width"
    t.integer "angled_view_height"
    t.integer "angled_view_width"
    t.integer "top_view_height"
    t.integer "top_view_width"
    t.integer "side_view_height"
    t.integer "side_view_width"
  end

  create_table "model_snub_crafts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_id", null: false
    t.uuid "snub_craft_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "model_upgrades", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.boolean "active", default: false
    t.boolean "hidden", default: true
    t.string "store_image"
    t.decimal "pledge_price", precision: 15, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "models", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.text "description"
    t.string "store_image", limit: 255
    t.string "store_url", limit: 255
    t.string "classification", limit: 255
    t.integer "rsi_id"
    t.uuid "manufacturer_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "production_status", limit: 255
    t.string "production_note", limit: 255
    t.string "focus", limit: 255
    t.boolean "on_sale", default: false
    t.decimal "pledge_price", precision: 15, scale: 2
    t.decimal "length", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "height", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "mass", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "cargo", precision: 15, scale: 2
    t.string "size"
    t.decimal "scm_speed", precision: 15, scale: 2
    t.integer "min_crew"
    t.integer "max_crew"
    t.decimal "pitch", precision: 15, scale: 2
    t.decimal "yaw", precision: 15, scale: 2
    t.decimal "roll", precision: 15, scale: 2
    t.string "fleetchart_image"
    t.datetime "store_images_updated_at", precision: nil
    t.boolean "hidden", default: true
    t.datetime "last_updated_at", precision: nil
    t.decimal "last_pledge_price", precision: 15, scale: 2
    t.string "rsi_name"
    t.string "rsi_slug"
    t.string "brochure"
    t.boolean "notified", default: false
    t.boolean "active", default: true
    t.decimal "price", precision: 15, scale: 2
    t.uuid "base_model_id"
    t.integer "rsi_chassis_id"
    t.decimal "rsi_height", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "rsi_length", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "rsi_beam", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "rsi_cargo", precision: 15, scale: 2
    t.integer "dock_size"
    t.boolean "ground", default: false
    t.integer "rsi_max_crew"
    t.integer "rsi_min_crew"
    t.decimal "rsi_scm_speed", precision: 15, scale: 2
    t.decimal "rsi_max_speed", precision: 15, scale: 2
    t.decimal "rsi_pitch", precision: 15, scale: 2
    t.decimal "rsi_yaw", precision: 15, scale: 2
    t.decimal "rsi_roll", precision: 15, scale: 2
    t.text "rsi_description"
    t.string "rsi_size"
    t.string "rsi_focus"
    t.string "rsi_classification"
    t.string "rsi_store_url"
    t.decimal "rsi_mass", precision: 15, scale: 2, default: "0.0", null: false
    t.string "sc_identifier"
    t.string "rsi_store_image"
    t.integer "model_paints_count", default: 0
    t.integer "images_count", default: 0
    t.integer "videos_count", default: 0
    t.integer "upgrade_kits_count", default: 0
    t.integer "module_hardpoints_count", default: 0
    t.decimal "max_speed", precision: 15, scale: 2
    t.decimal "hydrogen_fuel_tank_size", precision: 15, scale: 2
    t.decimal "quantum_fuel_tank_size", precision: 15, scale: 2
    t.string "cargo_holds"
    t.string "hydrogen_fuel_tanks"
    t.string "quantum_fuel_tanks"
    t.string "holo"
    t.boolean "holo_colored", default: false
    t.string "sales_page_url"
    t.string "top_view"
    t.string "side_view"
    t.string "erkul_identifier"
    t.decimal "fleetchart_offset_length", precision: 15, scale: 2
    t.string "angled_view"
    t.integer "fleetchart_image_height"
    t.integer "fleetchart_image_width"
    t.integer "angled_view_height"
    t.integer "angled_view_width"
    t.integer "top_view_height"
    t.integer "top_view_width"
    t.integer "side_view_height"
    t.integer "side_view_width"
    t.string "front_view"
    t.integer "front_view_width"
    t.integer "front_view_height"
    t.string "angled_view_colored"
    t.integer "angled_view_colored_width"
    t.integer "angled_view_colored_height"
    t.string "side_view_colored"
    t.integer "side_view_colored_width"
    t.integer "side_view_colored_height"
    t.string "top_view_colored"
    t.integer "top_view_colored_width"
    t.integer "top_view_colored_height"
    t.string "front_view_colored"
    t.integer "front_view_colored_width"
    t.integer "front_view_colored_height"
    t.decimal "ground_max_speed", precision: 15, scale: 2
    t.decimal "ground_reverse_speed", precision: 15, scale: 2
    t.decimal "ground_acceleration", precision: 15, scale: 2
    t.decimal "ground_decceleration", precision: 15, scale: 2
    t.decimal "scm_speed_acceleration", precision: 15, scale: 2
    t.decimal "scm_speed_decceleration", precision: 15, scale: 2
    t.decimal "max_speed_acceleration", precision: 15, scale: 2
    t.decimal "max_speed_decceleration", precision: 15, scale: 2
    t.integer "loaners_count", default: 0, null: false
    t.decimal "sc_length", precision: 15, scale: 2
    t.decimal "sc_beam", precision: 15, scale: 2
    t.decimal "sc_height", precision: 15, scale: 2
    t.decimal "scm_speed_boosted", precision: 15, scale: 2
    t.decimal "pitch_boosted", precision: 15, scale: 2
    t.decimal "yaw_boosted", precision: 15, scale: 2
    t.decimal "reverse_speed_boosted", precision: 15, scale: 2
    t.decimal "roll_boosted", precision: 15, scale: 2
    t.index ["base_model_id"], name: "index_models_on_base_model_id"
  end

  create_table "module_hardpoints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_id"
    t.uuid "model_module_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "oauth_access_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id", null: false
    t.uuid "application_id", null: false
    t.string "token", limit: 512, null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resource_owner_id"
    t.uuid "application_id", null: false
    t.string "token", limit: 512, null: false
    t.string "refresh_token", limit: 512
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", limit: 512, null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "owner_id"
    t.string "owner_type"
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "roadmap_items", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rsi_id"
    t.integer "rsi_category_id"
    t.integer "rsi_release_id"
    t.string "release"
    t.text "release_description"
    t.string "name"
    t.uuid "model_id"
    t.text "body"
    t.text "description"
    t.boolean "released", default: false
    t.string "image"
    t.integer "tasks"
    t.integer "inprogress"
    t.integer "completed"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "store_image"
    t.boolean "active", default: false
    t.boolean "committed", default: false
  end

  create_table "rollups", force: :cascade do |t|
    t.string "name", null: false
    t.string "interval", null: false
    t.datetime "time", precision: nil, null: false
    t.jsonb "dimensions", default: {}, null: false
    t.float "value"
    t.index ["name", "interval", "time", "dimensions"], name: "index_rollups_on_name_and_interval_and_time_and_dimensions", unique: true
  end

  create_table "rsi_request_logs", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "url"
    t.boolean "resolved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shop_commodities", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id"
    t.decimal "buy_price", precision: 15, scale: 2
    t.decimal "sell_price", precision: 15, scale: 2
    t.string "commodity_item_type"
    t.uuid "commodity_item_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "price_per_unit", default: false
    t.decimal "rental_price_1_day", precision: 15, scale: 2
    t.decimal "rental_price_7_days", precision: 15, scale: 2
    t.decimal "rental_price_30_days", precision: 15, scale: 2
    t.decimal "rental_price_3_days", precision: 15, scale: 2
    t.decimal "average_buy_price", precision: 15, scale: 2
    t.decimal "average_sell_price", precision: 15, scale: 2
    t.decimal "average_rental_price_1_day", precision: 15, scale: 2
    t.decimal "average_rental_price_3_days", precision: 15, scale: 2
    t.decimal "average_rental_price_7_days", precision: 15, scale: 2
    t.decimal "average_rental_price_30_days", precision: 15, scale: 2
    t.boolean "confirmed", default: false
    t.uuid "submitted_by"
    t.index ["commodity_item_id"], name: "index_shop_commodities_on_commodity_item_id"
    t.index ["commodity_item_type", "commodity_item_id"], name: "index_shop_commodities_on_item_type_and_item_id"
    t.index ["shop_id"], name: "index_shop_commodities_on_shop_id"
  end

  create_table "shops", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "store_image"
    t.uuid "station_id"
    t.integer "shop_type"
    t.boolean "hidden", default: true
    t.boolean "rental", default: false
    t.boolean "buying", default: false
    t.boolean "selling", default: false
    t.boolean "refinery_terminal", default: false
    t.text "description"
    t.string "location"
    t.index ["station_id"], name: "index_shops_on_station_id"
  end

  create_table "star_citizen_updates", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "url"
    t.string "title"
    t.string "news_type"
    t.string "news_sub_type"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "starsystems", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "map"
    t.string "store_image"
    t.integer "rsi_id"
    t.string "code"
    t.string "position_x"
    t.string "position_y"
    t.string "position_z"
    t.string "status"
    t.datetime "last_updated_at", precision: nil
    t.string "system_type"
    t.string "aggregated_size"
    t.integer "aggregated_population"
    t.integer "aggregated_economy"
    t.integer "aggregated_danger"
    t.boolean "hidden", default: true
    t.text "description"
    t.string "map_y"
    t.string "map_x"
  end

  create_table "stations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.uuid "planet_id"
    t.integer "station_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "hidden", default: true
    t.string "store_image"
    t.string "location"
    t.string "map"
    t.text "description"
    t.uuid "celestial_object_id"
    t.integer "status"
    t.integer "images_count", default: 0
    t.boolean "cargo_hub", default: false
    t.boolean "refinery", default: false
    t.integer "classification"
    t.boolean "habitable", default: true
    t.integer "size"
    t.index ["celestial_object_id"], name: "index_stations_on_celestial_object_id"
    t.index ["name"], name: "index_stations_on_name", unique: true
    t.index ["planet_id"], name: "index_stations_on_planet_id"
  end

  create_table "task_forces", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "hangar_group_id"
    t.uuid "vehicle_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["hangar_group_id"], name: "index_task_forces_on_hangar_group_id"
    t.index ["vehicle_id"], name: "index_task_forces_on_vehicle_id"
  end

  create_table "trade_routes", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "origin_id"
    t.uuid "origin_station_id"
    t.uuid "origin_celestial_object_id"
    t.uuid "origin_starsystem_id"
    t.uuid "destination_id"
    t.uuid "destination_station_id"
    t.uuid "destination_celestial_object_id"
    t.uuid "destination_starsystem_id"
    t.decimal "profit_per_unit", precision: 15, scale: 2
    t.decimal "profit_per_unit_percent", precision: 15, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "average_profit_per_unit", precision: 15, scale: 2
    t.decimal "average_profit_per_unit_percent", precision: 15, scale: 2
    t.index ["destination_celestial_object_id"], name: "index_trade_routes_on_destination_celestial_object_id"
    t.index ["destination_id"], name: "index_trade_routes_on_destination_id"
    t.index ["destination_starsystem_id"], name: "index_trade_routes_on_destination_starsystem_id"
    t.index ["destination_station_id"], name: "index_trade_routes_on_destination_station_id"
    t.index ["origin_celestial_object_id"], name: "index_trade_routes_on_origin_celestial_object_id"
    t.index ["origin_id", "destination_id"], name: "index_trade_routes_on_origin_id_and_destination_id", unique: true
    t.index ["origin_starsystem_id"], name: "index_trade_routes_on_origin_starsystem_id"
    t.index ["origin_station_id"], name: "index_trade_routes_on_origin_station_id"
  end

  create_table "upgrade_kits", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_id"
    t.uuid "model_upgrade_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "locale", limit: 255
    t.string "username", limit: 255, default: "", null: false
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email", limit: 255
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token", limit: 255
    t.datetime "locked_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "sale_notify", default: false
    t.boolean "tracking", default: true
    t.boolean "public_hangar", default: true
    t.string "avatar"
    t.string "twitch"
    t.string "discord"
    t.string "rsi_handle"
    t.string "youtube"
    t.string "homepage"
    t.string "guilded"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.boolean "public_hangar_loaners", default: false
    t.string "normalized_username"
    t.string "normalized_email"
    t.datetime "hangar_updated_at", precision: nil
    t.string "otp_secret"
    t.boolean "public_wishlist", default: false
    t.boolean "hide_owner", default: false, null: false
    t.datetime "last_active_at"
    t.boolean "tester", default: false
    t.integer "purchased_vehicles_count", default: 0, null: false
    t.integer "wanted_vehicles_count", default: 0, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["normalized_username"], name: "index_users_on_normalized_username"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicle_modules", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_module_id"
    t.uuid "vehicle_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "rsi_pledge_id"
    t.datetime "rsi_pledge_synced_at"
  end

  create_table "vehicle_upgrades", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "model_upgrade_id"
    t.uuid "vehicle_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "rsi_pledge_id"
    t.datetime "rsi_pledge_synced_at"
  end

  create_table "vehicles", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "model_id"
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "sale_notify", default: false
    t.boolean "flagship", default: false
    t.boolean "name_visible", default: false
    t.boolean "public", default: false
    t.uuid "vehicle_id"
    t.boolean "loaner", default: false
    t.boolean "hidden", default: false
    t.uuid "model_paint_id"
    t.boolean "notify", default: true
    t.string "serial"
    t.string "alternative_names"
    t.uuid "module_package_id"
    t.boolean "wanted", default: false
    t.integer "bought_via", default: 0
    t.string "rsi_pledge_id"
    t.datetime "rsi_pledge_synced_at"
    t.string "slug"
    t.index ["model_id", "id"], name: "index_vehicles_on_model_id_and_id"
    t.index ["serial", "user_id"], name: "index_vehicles_on_serial_and_user_id", unique: true
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end

  create_table "versions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "item_type", null: false
    t.uuid "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "old_object"
    t.datetime "created_at", precision: nil
    t.text "old_object_changes"
    t.json "object"
    t.json "object_changes"
    t.uuid "author_id"
    t.string "reason"
    t.text "reason_description"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "videos", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "url"
    t.integer "video_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "model_id"
    t.index ["model_id"], name: "index_videos_on_model_id"
  end

  create_table "youtube_updates", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "video_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "hardpoints", "components"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
end
