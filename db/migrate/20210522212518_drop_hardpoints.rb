class DropHardpoints < ActiveRecord::Migration[6.1]
  def up
    drop_table :hardpoints
  end

  def down
    create_table "hardpoints", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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
      t.string "rsi_key"
      t.datetime "deleted_at"
      t.string "key"
      t.index ["component_id"], name: "index_hardpoints_on_component_id"
      t.index ["model_id"], name: "index_hardpoints_on_model_id"
    end
  end
end
