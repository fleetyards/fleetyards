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

ActiveRecord::Schema.define(version: 20181220185616) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "affiliations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "affiliationable_type"
    t.uuid "affiliationable_id"
    t.uuid "faction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliationable_type", "affiliationable_id"], name: "index_affiliations_on_affiliationable"
    t.index ["faction_id"], name: "index_affiliations_on_faction_id"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.uuid "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
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
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "albums", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "slug", limit: 255
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.boolean "permanent", default: false
    t.string "client_key"
    t.string "browser"
    t.string "platform"
    t.index ["user_id"], name: "index_auth_tokens_on_user_id"
  end

  create_table "celestial_objects", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.uuid "starsystem_id"
    t.string "object_type"
    t.integer "rsi_id"
    t.string "code"
    t.string "status"
    t.string "designation"
    t.datetime "last_updated_at"
    t.text "description"
    t.boolean "hidden", default: true
    t.string "orbit_period"
    t.boolean "habitable"
    t.boolean "fairchanceact"
    t.integer "sensor_population"
    t.integer "sensor_economy"
    t.integer "sensor_danger"
    t.string "size"
    t.string "sub_type"
    t.string "store_image"
    t.uuid "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["starsystem_id"], name: "index_celestial_objects_on_starsystem_id"
  end

  create_table "commodities", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "store_image"
  end

  create_table "commodity_prices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "key"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "components", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "size", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.uuid "manufacturer_id"
    t.string "component_class"
    t.string "slug"
    t.string "item_type"
    t.text "description"
    t.string "store_image"
    t.string "grade"
    t.integer "item_class"
    t.index ["manufacturer_id"], name: "index_components_on_manufacturer_id"
  end

  create_table "docks", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer "dock_type"
    t.uuid "station_id"
    t.string "name"
    t.integer "max_ship_size"
    t.integer "min_ship_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ship_size"
    t.index ["station_id"], name: "index_docks_on_station_id"
  end

  create_table "equipment", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "store_image"
    t.integer "equipment_type"
    t.boolean "hidden", default: true
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "manufacturer_id"
    t.integer "item_type"
    t.string "size"
    t.string "grade"
    t.integer "damage_reduction"
    t.integer "rate_of_fire"
    t.integer "range"
    t.string "extras"
    t.integer "weapon_class"
    t.integer "slot"
    t.index ["manufacturer_id"], name: "index_equipment_on_manufacturer_id"
  end

  create_table "factions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer "rsi_id"
    t.string "name"
    t.string "slug"
    t.string "code"
    t.string "color"
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
    t.hstore "rsi_members", default: [], null: false, array: true
    t.string "banner"
    t.string "background"
  end

  create_table "habitations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.integer "habitation_type"
    t.uuid "station_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["station_id"], name: "index_habitations_on_station_id"
  end

  create_table "hangar_groups", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "color"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sort"
    t.index ["user_id"], name: "index_hangar_groups_on_user_id"
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
    t.boolean "default_empty", default: false
    t.index ["component_id"], name: "index_hardpoints_on_component_id"
    t.index ["model_id"], name: "index_hardpoints_on_model_id"
  end

  create_table "images", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name", limit: 255
    t.uuid "gallery_id"
    t.string "gallery_type", limit: 255
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "background", default: true
    t.integer "width"
    t.integer "height"
    t.index ["gallery_id"], name: "index_images_on_gallery_id"
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

  create_table "model_modules", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.uuid "manufacturer_id"
    t.uuid "model_id"
    t.boolean "active", default: true
    t.boolean "hidden", default: true
    t.string "production_status"
    t.string "store_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "pledge_price", precision: 15, scale: 2
  end

  create_table "model_upgrades", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.boolean "active", default: false
    t.boolean "hidden", default: true
    t.string "store_image"
    t.decimal "pledge_price", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.decimal "afterburner_speed", precision: 15, scale: 2
    t.decimal "cruise_speed", precision: 15, scale: 2
    t.integer "min_crew"
    t.integer "max_crew"
    t.decimal "pitch_max", precision: 15, scale: 2
    t.decimal "yaw_max", precision: 15, scale: 2
    t.decimal "roll_max", precision: 15, scale: 2
    t.decimal "xaxis_acceleration", precision: 15, scale: 2
    t.decimal "yaxis_acceleration", precision: 15, scale: 2
    t.decimal "zaxis_acceleration", precision: 15, scale: 2
    t.string "fleetchart_image"
    t.datetime "store_images_updated_at"
    t.boolean "hidden", default: true
    t.datetime "last_updated_at"
    t.decimal "fallback_beam", precision: 15, scale: 2
    t.decimal "fallback_length", precision: 15, scale: 2
    t.decimal "fallback_height", precision: 15, scale: 2
    t.decimal "fallback_mass", precision: 15, scale: 2
    t.decimal "fallback_cargo", precision: 15, scale: 2
    t.decimal "fallback_scm_speed", precision: 15, scale: 2
    t.decimal "fallback_afterburner_speed", precision: 15, scale: 2
    t.decimal "fallback_cruise_speed", precision: 15, scale: 2
    t.integer "fallback_min_crew"
    t.integer "fallback_max_crew"
    t.decimal "fallback_pledge_price", precision: 15, scale: 2
    t.string "rsi_name"
    t.string "rsi_slug"
    t.string "brochure"
    t.decimal "ground_speed", precision: 15, scale: 2
    t.decimal "afterburner_ground_speed", precision: 15, scale: 2
    t.boolean "notified", default: false
    t.boolean "active", default: true
    t.decimal "price", precision: 15, scale: 2
    t.uuid "base_model_id"
    t.integer "rsi_chassis_id"
    t.index ["base_model_id"], name: "index_models_on_base_model_id"
  end

  create_table "module_hardpoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "model_id"
    t.uuid "model_module_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shop_commodities", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "shop_id"
    t.decimal "buy_price", precision: 15, scale: 2
    t.decimal "sell_price", precision: 15, scale: 2
    t.decimal "rent_price", precision: 15, scale: 2
    t.string "commodity_item_type"
    t.uuid "commodity_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commodity_item_id"], name: "index_shop_commodities_on_commodity_item_id"
    t.index ["commodity_item_type", "commodity_item_id"], name: "index_shop_commodities_on_item_type_and_item_id"
    t.index ["shop_id"], name: "index_shop_commodities_on_shop_id"
  end

  create_table "shops", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "store_image"
    t.uuid "station_id"
    t.integer "shop_type"
    t.boolean "hidden", default: true
    t.boolean "rental", default: false
    t.boolean "buying", default: false
    t.boolean "selling", default: false
    t.index ["station_id"], name: "index_shops_on_station_id"
  end

  create_table "starsystems", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "map"
    t.string "store_image"
    t.integer "rsi_id"
    t.string "code"
    t.string "position_x"
    t.string "position_y"
    t.string "position_z"
    t.string "status"
    t.datetime "last_updated_at"
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

  create_table "stations", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.uuid "planet_id"
    t.integer "station_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: true
    t.string "store_image"
    t.string "location"
    t.string "map"
    t.text "description"
    t.uuid "celestial_object_id"
    t.integer "status"
    t.index ["celestial_object_id"], name: "index_stations_on_celestial_object_id"
    t.index ["planet_id"], name: "index_stations_on_planet_id"
  end

  create_table "task_forces", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "hangar_group_id"
    t.uuid "vehicle_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hangar_group_id"], name: "index_task_forces_on_hangar_group_id"
    t.index ["vehicle_id"], name: "index_task_forces_on_vehicle_id"
  end

  create_table "trade_commodities", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "trade_hub_id"
    t.uuid "commodity_id"
    t.decimal "buy_price", precision: 15, scale: 2, default: "0.0"
    t.decimal "sell_price", precision: 15, scale: 2, default: "0.0"
    t.boolean "buy"
    t.boolean "sell"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trade_hub_id"], name: "index_trade_commodities_on_trade_hub_id"
  end

  create_table "trade_hubs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "planet"
    t.string "system"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "station_type"
  end

  create_table "upgrade_kits", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "model_id"
    t.uuid "model_upgrade_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.boolean "sale_notify", default: false
    t.string "rsi_org"
    t.boolean "rsi_verified", default: false
    t.string "rsi_verification_token"
    t.string "rsi_orgs"
    t.boolean "tracking", default: true
    t.boolean "public_hangar", default: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicle_modules", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "model_module_id"
    t.uuid "vehicle_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vehicle_upgrades", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "model_upgrade_id"
    t.uuid "vehicle_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vehicles", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "model_id"
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "purchased", default: false
    t.boolean "sale_notify", default: false
    t.boolean "flagship", default: false
    t.boolean "name_visible", default: false
    t.boolean "public", default: true
    t.index ["model_id"], name: "index_vehicles_on_model_id"
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end

  create_table "videos", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "url"
    t.integer "video_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "model_id"
    t.index ["model_id"], name: "index_videos_on_model_id"
  end

end
