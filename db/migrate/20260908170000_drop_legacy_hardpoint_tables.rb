class DropLegacyHardpointTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :vehicle_loadout_hardpoints
    drop_table :model_hardpoint_loadouts
    drop_table :model_hardpoints
  end

  def down
    create_table "model_hardpoints", id: :uuid, default: -> { "public.gen_random_uuid()" } do |t|
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

    create_table "model_hardpoint_loadouts", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid "component_id"
      t.datetime "created_at", null: false
      t.uuid "model_hardpoint_id"
      t.string "name"
      t.datetime "updated_at", null: false
    end

    create_table "vehicle_loadout_hardpoints", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid "component_id"
      t.datetime "created_at", null: false
      t.uuid "model_hardpoint_id", null: false
      t.datetime "updated_at", null: false
      t.uuid "vehicle_loadout_id", null: false
      t.index ["vehicle_loadout_id", "model_hardpoint_id"], name: "idx_vehicle_loadout_hardpoints_unique", unique: true
    end

    add_foreign_key "vehicle_loadout_hardpoints", "components"
    add_foreign_key "vehicle_loadout_hardpoints", "model_hardpoints"
    add_foreign_key "vehicle_loadout_hardpoints", "vehicle_loadouts"
  end
end
