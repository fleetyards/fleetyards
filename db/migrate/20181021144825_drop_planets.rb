class DropPlanets < ActiveRecord::Migration[5.2]
  def up
    drop_table :planets
  end

  def down
    create_table "planets", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.uuid "starsystem_id"
      t.uuid "planet_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "map"
      t.string "store_image"
      t.index ["planet_id"], name: "index_planets_on_planet_id"
      t.index ["starsystem_id"], name: "index_planets_on_starsystem_id"
    end
  end
end
