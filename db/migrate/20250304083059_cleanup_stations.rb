class CleanupStations < ActiveRecord::Migration[7.2]
  def change
    drop_table "affiliations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
      t.string "affiliationable_type"
      t.uuid "affiliationable_id"
      t.uuid "faction_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["affiliationable_type", "affiliationable_id"], name: "index_affiliations_on_affiliationable"
      t.index ["faction_id"], name: "index_affiliations_on_faction_id"
    end

    drop_table "celestial_objects", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    drop_table "commodities", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.text "description"
      t.string "store_image"
      t.integer "commodity_type"
      t.index ["name"], name: "index_commodities_on_name", unique: true
    end

    drop_table "commodity_prices", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    remove_column :docks, :station_id, :uuid

    drop_table "factions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
      t.integer "rsi_id"
      t.string "name"
      t.string "slug"
      t.string "code"
      t.string "color"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    drop_table "habitations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
      t.string "name"
      t.integer "habitation_type"
      t.uuid "station_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "habitation_name"
      t.index ["station_id"], name: "index_habitations_on_station_id"
    end

    drop_table "roadmap_items", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    drop_table "shop_commodities", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    drop_table "shops", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    drop_table "starsystems", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    drop_table "stations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

    drop_table "trade_routes", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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
  end
end
