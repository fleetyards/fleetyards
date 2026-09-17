# frozen_string_literal: true

# Where a blueprint comes from: the reward pool that hands it out, and whatever
# hands that pool out.
#
# Hung off the build rather than the blueprint, for the reason the recipe is
# (`blueprint_cost_slots`): live and ptu are loaded separately and a reader can
# be pointed at either, so a single global set would leave whichever tree loaded
# last answering for both. `prune_builds` and `retire_absent_builds` drop a build
# with `delete_all`, which skips `dependent: :destroy`, so the cascade here is
# what carries the sources away with it.
#
# Denormalised on purpose. A pool, an org and a mission are all records in the
# export, but none of them is a Fleetyards entity and nothing else would point
# at one -- three tables to render one sentence is a worse trade than a wide row
# the loader rewrites wholesale.
class CreateBlueprintSources < ActiveRecord::Migration[8.1]
  def change
    create_table :blueprint_sources, id: :uuid do |t|
      t.references :blueprint_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_blueprint_sources_on_build"}

      # "contract" -- a mission a generator offers -- or "scenario", which is
      # XenoThreat handing pools out by progress points instead.
      t.string :kind, null: false

      # The pool itself. `pool_group` is its folder, the only grouping the
      # export gives: blueprintmissionpools, ors, xenothreat2rewards,
      # collectorwikelo, 48blueprints.
      t.string :pool_sc_ref, null: false
      t.string :pool_key
      t.string :pool_group

      # Uniform at 1 across all 818 reward entries in 4.10.1, so nothing can be
      # said about relative odds yet. Stored because this is the only field
      # that could ever say otherwise.
      t.decimal :weight, precision: 8, scale: 3

      # The org whose missions hand it out. Nullable: nine pool-bearing
      # handlers sit in a generator naming more than one faction, and a wrong
      # org is worse than none when "who gives me this" is the whole question.
      t.string :org_ref
      t.string :org_name

      # "Yellow Level Contract: Ambush An Amateur", and the reputation band it
      # is offered in -- which is what a player reads as VHRT and up.
      t.string :source_key
      t.string :mission_name
      t.string :min_standing
      t.string :max_standing

      # Scenario only: the progress points that unlock the tier.
      t.integer :min_points

      t.integer :position, null: false

      t.timestamps
    end

    add_index :blueprint_sources, [:blueprint_build_id, :position],
      unique: true, name: "index_blueprint_sources_on_build_and_position"

    # "Which blueprints does this org hand out", which is a filter the list
    # needs and the reverse of what the detail page asks.
    add_index :blueprint_sources, [:org_name]
  end
end
