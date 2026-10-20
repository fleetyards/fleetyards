# frozen_string_literal: true

# What a player has to have, or not have, before a mission is offered.
#
# Hung off the build like the rewards, so live and ptu each keep their own, and
# carried away by the same cascade when `prune_builds` drops one.
class CreateGameMissionPrerequisites < ActiveRecord::Migration[8.1]
  def change
    create_table :game_mission_prerequisites, id: :uuid do |t|
      t.references :game_mission_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_game_mission_prerequisites_on_build"}

      # "crime_stat", "reputation", "completed_missions" or "excluded_missions".
      t.string :kind, null: false

      # Crime stat only: the band a player's CrimeStat has to sit in.
      t.integer :min
      t.integer :max

      # Reputation only: whose standing, the band, and whether the player has
      # to be outside it instead.
      t.string :org_key
      t.string :org_name
      t.string :min_standing
      t.string :max_standing
      t.boolean :excluded, default: false, null: false

      # Completed missions only: how many of the contracts granting the
      # required tags, and those contracts by `sc_ref`.
      t.integer :count
      t.text :mission_refs, array: true, default: [], null: false
      # Whether the mission itself grants what it asks about: excluded, it can
      # be done once only; required, it counts its own repeats.
      t.boolean :includes_self, default: false, null: false

      t.integer :position, null: false

      t.timestamps
    end

    add_index :game_mission_prerequisites, [:game_mission_build_id, :position],
      unique: true, name: "index_game_mission_prerequisites_on_build_and_position"
  end
end
