# frozen_string_literal: true

# What a mission pays, as the game files state it.
#
# Which is reputation, items and badges -- and, for 8 of the 2536 contracts, a
# currency figure. The other 2352 award `ContractResult_CalculatedReward`, an
# empty element: the game computes that number at run time and the export holds
# no table, curve or scalar to compute it from. There is deliberately no payout
# column anywhere for the rest of them to be empty in.
#
# Hung off the build rather than the mission, for the reason `blueprint_sources`
# is: live and ptu load separately, and a single global set would leave whichever
# loaded last answering for both. `prune_builds` and `retire_absent_builds` drop
# a build with `delete_all`, which skips `dependent: :destroy`, so the cascade
# here is what carries the rewards away with it.
class CreateGameMissionRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :game_mission_rewards, id: :uuid do |t|
      t.references :game_mission_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_game_mission_rewards_on_build"}

      # "reputation", "item", "badge" or "currency".
      t.string :kind, null: false

      # Reputation points, an item count, or aUEC. `max` is the top of a stated
      # range and is only ever set alongside a currency amount.
      t.integer :amount
      t.integer :max

      # "UEC" on seven of the eight, "MER" -- mercenary scrip -- on the other.
      t.string :currency

      # Reputation only: whose standing moves, which is not always the org
      # offering the contract.
      t.string :org_key
      t.string :org_name

      # Item only. The entity class GUID is not resolved to a catalogue row
      # here: an award names entities that are variously equipment, a commodity
      # crate or a mission carryable in no catalogue at all.
      t.string :entity_class

      # Item only, and only for an award drawn from weighted sets: which set
      # this entry belonged to, so a page can say one of these rather than all.
      t.decimal :weight, precision: 8, scale: 3

      # Badge only: "WelcomeToPyro_Firesale". The export states the key and
      # nothing that resolves it.
      t.string :badge

      t.integer :position, null: false

      t.timestamps
    end

    add_index :game_mission_rewards, [:game_mission_build_id, :position],
      unique: true, name: "index_game_mission_rewards_on_build_and_position"

    add_index :game_mission_rewards, :kind
  end
end
