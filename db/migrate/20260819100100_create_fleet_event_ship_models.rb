# frozen_string_literal: true

class CreateFleetEventShipModels < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_event_ship_models, id: :uuid do |t|
      t.references :fleet_event_ship, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade},
        index: {name: "index_fleet_event_ship_models_on_ship"}
      # Cascade rather than nullify: the row exists to name one allowed model, so
      # an sc_data import retiring that model should drop it from the list
      # instead of leaving an entry that matches nothing.
      t.references :model, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :fleet_event_ship_models, [:fleet_event_ship_id, :model_id],
      unique: true, name: "index_fleet_event_ship_models_on_ship_and_model"
    add_index :fleet_event_ship_models, [:fleet_event_ship_id, :position],
      name: "index_fleet_event_ship_models_on_ship_and_position"
  end
end
