class CreateVehicleLoadouts < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicle_loadouts, id: :uuid do |t|
      t.references :vehicle, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.boolean :active, default: false, null: false
      t.string :erkul_url
      t.string :spviewer_url
      t.timestamps
    end

    add_index :vehicle_loadouts, :vehicle_id
    add_index :vehicle_loadouts, [:vehicle_id, :name], unique: true

    create_table :vehicle_loadout_hardpoints, id: :uuid do |t|
      t.references :vehicle_loadout, type: :uuid, null: false, foreign_key: true, index: false
      t.references :model_hardpoint, type: :uuid, null: false, foreign_key: true, index: false
      t.references :component, type: :uuid, foreign_key: true, index: false
      t.timestamps
    end

    add_index :vehicle_loadout_hardpoints, :vehicle_loadout_id
    add_index :vehicle_loadout_hardpoints, [:vehicle_loadout_id, :model_hardpoint_id],
      unique: true, name: :idx_vehicle_loadout_hardpoints_unique
  end
end
