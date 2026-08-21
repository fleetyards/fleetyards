# frozen_string_literal: true

class CreateMissionShipModels < ActiveRecord::Migration[8.1]
  def change
    create_table :mission_ship_models, id: :uuid do |t|
      t.references :mission_ship, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}
      # Cascade rather than nullify: the row exists to name one allowed model, so
      # an sc_data import retiring that model should drop it from the list
      # instead of leaving an entry that matches nothing.
      t.references :model, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :mission_ship_models, [:mission_ship_id, :model_id], unique: true,
      name: "index_mission_ship_models_on_ship_and_model"
    add_index :mission_ship_models, [:mission_ship_id, :position],
      name: "index_mission_ship_models_on_ship_and_position"
  end
end
