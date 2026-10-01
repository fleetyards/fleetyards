# frozen_string_literal: true

class CreateGameMissionLocations < ActiveRecord::Migration[8.1]
  def change
    # Where a mission can take place. `template` comes from the location
    # templates its slots can pick, `text` from a place its title or
    # description names.
    create_table :game_mission_locations, id: :uuid do |t|
      t.references :game_mission, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.references :location, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :source, null: false

      t.timestamps
    end

    add_index :game_mission_locations, [:game_mission_id, :location_id, :source], unique: true, name: "index_game_mission_locations_uniqueness"
  end
end
