# frozen_string_literal: true

# What one build of the game says about a mission, following the shape
# `blueprint_builds`, `commodity_builds`, `equipment_builds` and
# `component_builds` established.
#
# Everything a patch can rewrite lives here rather than on the row: a contract
# is retitled, moved to another standing band, or taken out of release between
# builds, and live and ptu are loaded separately.
class CreateGameMissionBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :game_mission_builds, id: :uuid do |t|
      t.references :game_mission, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      # "career" or "contract" -- the element the contract is declared as, which
      # is the only place the export says which of the two it is.
      t.string :kind

      # As a player reads them, and as the export writes them: both carry
      # `~mission(Location|Address)` spans the game fills in at run time, and
      # the description carries the game's own `<EM4>` emphasis markup. Rendered
      # rather than stripped, so the sentence around a span survives.
      t.string :name
      t.text :description

      # Where in the tree it came from. `debug_name` is a developer's note, not
      # for reading -- kept because it is half the stable key and the only way
      # to find the record again in the export.
      t.string :generator_key
      t.string :debug_name

      # The org that offers it. Null on 197 of them: a handler that names no
      # faction takes its generator's, and only where that generator names
      # exactly one -- a wrong org is worse than none when "who gives me this"
      # is the question the row answers.
      t.string :org_ref
      t.string :org_key
      t.string :org_name

      # What the export states (a boolean, on all 38 reputation records) and
      # what we curate from it. Neutral is ours to name, so it is resolved by
      # the loader against `org_key` and shares `BlueprintSource`'s list.
      t.boolean :org_lawful
      t.string :alignment

      # The reputation band the contract is offered in, which is what a player
      # reads as VHRT and up.
      t.string :min_standing
      t.string :max_standing

      # False where the contract is flagged `notForRelease` or `workInProgress`
      # -- 349 of the 2536. In the files, but not in front of anybody.
      t.boolean :released, null: false, default: true

      # Four axes, each a 1-7 the export writes on the end of a designer's
      # sentence ("Hard_PvE_or_Easy_PvP_action_5"). The prose is developer
      # facing; the number is the half worth showing. `difficulty_profile` names
      # the record holding the weights the game combines them with.
      t.string :difficulty_profile
      t.integer :difficulty_mechanical_skill
      t.integer :difficulty_mental_load
      t.integer :difficulty_risk_of_loss
      t.integer :difficulty_game_knowledge

      # Denormalised off `game_mission_rewards` so "missions that pay
      # reputation" is an index lookup rather than an exists check per row.
      t.text :reward_kinds, null: false, default: [], array: true

      # The reward pools this mission hands out, by ref. An array rather than a
      # table: a pool is not an entity here, `blueprint_sources.pool_sc_ref`
      # already carries the other end, and nothing will ever point at a row.
      t.text :blueprint_pool_refs, null: false, default: [], array: true

      t.timestamps
    end

    add_index :game_mission_builds, [:game_mission_id, :environment, :version],
      unique: true, name: "index_game_mission_builds_on_mission_and_build"

    add_index :game_mission_builds, [:environment, :version]
    add_index :game_mission_builds, [:environment, :name]
    add_index :game_mission_builds, [:environment, :org_name]
    add_index :game_mission_builds, :reward_kinds, using: :gin
    add_index :game_mission_builds, :blueprint_pool_refs, using: :gin
  end
end
