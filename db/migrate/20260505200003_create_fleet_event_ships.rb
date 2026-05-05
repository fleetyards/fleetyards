# frozen_string_literal: true

class CreateFleetEventShips < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_event_ships, id: :uuid do |t|
      t.references :fleet_event_team, type: :uuid, null: false, foreign_key: true
      t.uuid :source_ship_id
      t.references :model, type: :uuid, null: true, foreign_key: true
      t.string :title
      t.text :description
      t.string :classification
      t.string :focus
      t.string :min_size
      t.string :max_size
      t.integer :min_crew
      t.decimal :min_cargo
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :fleet_event_ships, [:fleet_event_team_id, :position]
    add_foreign_key :fleet_event_ships, :mission_ships, column: :source_ship_id, on_delete: :nullify
  end
end
