# frozen_string_literal: true

# What a mission asks to be brought to it: Wikelo's trades, the ore a mining
# contract wants, the salvage a salvage contract wants.
#
# Hung off the build, like the rewards, so live and ptu each keep their own.
# `prune_builds` and `retire_absent_builds` drop a build with `delete_all`, which
# skips `dependent: :destroy`, so the cascade is what carries these away.
class CreateGameMissionHandIns < ActiveRecord::Migration[8.1]
  def change
    create_table :game_mission_hand_ins, id: :uuid do |t|
      t.references :game_mission_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_game_mission_hand_ins_on_build"}

      # "item" or "resource".
      t.string :kind, null: false

      # An entity class, or a group record accepting any of several, for an
      # item; a resource type for a resource.
      t.string :ref, null: false
      t.string :name

      # A count for an item, SCU for a resource. `max` only where the contract
      # states a range.
      t.integer :amount, null: false
      t.integer :max

      # Set where the contract offers a choice: entries sharing an option are
      # one alternative, and any one option satisfies it. Null is always asked.
      t.integer :option

      # The catalogue row it names, where one exists: a component, a piece of
      # equipment or a commodity. Null for the rest -- carryables no catalogue
      # holds, and "any of" groups.
      t.references :catalogue_item, polymorphic: true, type: :uuid, index: false

      t.integer :position, null: false

      t.timestamps
    end

    add_index :game_mission_hand_ins, [:game_mission_build_id, :position],
      unique: true, name: "index_game_mission_hand_ins_on_build_and_position"
  end
end
