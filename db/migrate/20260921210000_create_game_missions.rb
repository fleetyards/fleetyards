# frozen_string_literal: true

# A contract the game can offer: who wants it done, what it takes to be offered
# it, and what finishing it pays.
#
# `GameMission` rather than `Mission` or `Contract`, both of which are fleet
# features here -- the mission planner and the logistics ledger. "Contract" is
# taken twice over: `config/routes/api/fleets_routes.rb` mounts fleet contracts
# at `contracts`, so the generated API client already has a service by that name.
#
# The fact columns are mirrored from `game_mission_builds`, the way `blueprints`
# mirrors `blueprint_builds`. Two reasons, and the second is not optional:
# a mission the export drops keeps describing itself off the row, and
# `all_facts_join` reads `COALESCE(b.fact, p.fact)` with `p` being this table --
# a filterable fact that is not a column here is a filter that cannot run.
class CreateGameMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_missions, id: :uuid do |t|
      # The contract's own `id` attribute. Unique across all 2536 in 4.10.1,
      # and what `blueprint_sources` will point at when it stops carrying its
      # own copy of the mission.
      t.string :sc_ref, null: false

      # `<generator>_<debugName>`, flattened to something that can be a file
      # name. Neither half is unique alone; together they leave 13 pairs, and
      # those take the head of their GUID. See `ScData::Parser::ContractsParser`.
      t.string :sc_key, null: false
      t.string :slug, null: false

      t.string :name
      t.text :description
      t.string :kind

      t.string :generator_key
      t.string :debug_name

      t.string :org_ref
      t.string :org_key
      t.string :org_name
      t.boolean :org_lawful
      t.string :alignment

      t.string :min_standing
      t.string :max_standing

      t.boolean :released, null: false, default: true

      t.string :difficulty_profile
      t.integer :difficulty_mechanical_skill
      t.integer :difficulty_mental_load
      t.integer :difficulty_risk_of_loss
      t.integer :difficulty_game_knowledge

      t.text :reward_kinds, null: false, default: [], array: true
      t.text :blueprint_pool_refs, null: false, default: [], array: true

      t.string :version

      t.timestamps
    end

    add_index :game_missions, :sc_ref, unique: true
    add_index :game_missions, :sc_key, unique: true
    add_index :game_missions, :slug, unique: true
    add_index :game_missions, :version
    add_index :game_missions, :org_name
  end
end
