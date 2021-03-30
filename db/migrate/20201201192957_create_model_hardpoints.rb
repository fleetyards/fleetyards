class CreateModelHardpoints < ActiveRecord::Migration[6.0]
  def change
    create_table :model_hardpoints, id: :uuid do |t|
      t.integer :size
      t.integer :source
      t.string :key
      t.integer :hardpoint_type
      t.integer :category
      t.integer :group
      t.uuid :model_id
      t.uuid :component_id
      t.datetime :deleted_at
      t.string :details
      t.string :mount
      t.integer :item_slots

      t.timestamps

      t.index ["component_id"], name: "index_model_hardpoints_on_component_id"
      t.index ["model_id"], name: "index_model_hardpoints_on_model_id"
    end
  end
end
