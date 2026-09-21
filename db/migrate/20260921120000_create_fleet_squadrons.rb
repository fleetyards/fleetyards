# frozen_string_literal: true

class CreateFleetSquadrons < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_squadrons, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :color
      t.timestamps
    end

    add_index :fleet_squadrons, [:fleet_id, :slug], unique: true
    add_index :fleet_squadrons, "fleet_id, LOWER(name)", unique: true,
      name: "index_fleet_squadrons_on_fleet_id_and_lower_name"
  end
end
