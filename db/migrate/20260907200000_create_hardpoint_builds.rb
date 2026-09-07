# frozen_string_literal: true

# What one build of the game says about a hardpoint, following the shape the four
# catalogue build tables established.
#
# The loadout is the one thing the row-per-build work never covered. `hardpoints`
# carries no environment, and `persist_loadout` destroys every game-file row the
# loaded build does not name -- so loading PTU replaces live's loadouts in place.
# See item 2 of docs/exec-plans/sc-data-live-and-ptu.md.
#
# The split is one layer deeper than the catalogues need, because a loadout
# differs between builds in *structure* and not only in facts: the slot -- parent
# plus `sc_name` -- stays on `hardpoints` and is what `ModelPosition` already
# points at, while what a build says is in it moves here. A slot the build does
# not describe simply has no row here, which is what replaces the destroy.
#
# Nothing reads this yet.
class CreateHardpointBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :hardpoint_builds, id: :uuid do |t|
      # Cascade: a build says something about a slot, and says nothing at all
      # once the slot is gone.
      t.references :hardpoint, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      # What is installed is the loadout. No foreign key constraint, matching
      # `hardpoints.component_id`, which has one -- but here a build may name a
      # component a later load retires, and the row still has to describe the
      # build it belongs to.
      t.uuid :component_id

      t.integer :min_size
      t.integer :max_size

      # Serialized as JSON arrays on the model, the same as on `hardpoints`.
      t.string :types
      t.string :port_tags
      t.string :required_tags
      t.string :flags

      # Derived from the component by Hardpoint's `before_validation`, so they
      # move with it rather than staying on the slot.
      t.integer :group
      t.integer :category
      t.string :group_key

      t.timestamps
    end

    # One row per slot per build. Re-loading the same build updates it in place;
    # a new build adds a row beside it.
    add_index :hardpoint_builds, [:hardpoint_id, :environment, :version],
      unique: true, name: "index_hardpoint_builds_on_hardpoint_and_build"

    # Every read names an environment and a version, because that pair is what
    # `ScData::Source` hands out.
    add_index :hardpoint_builds, [:environment, :version]
    add_index :hardpoint_builds, :component_id

    # The slot's natural key, and only on the game-files side. Unique in fact
    # there already -- 0 duplicates over the 22,561 rows -- but nothing enforced
    # it except `find_or_initialize_by` in the loader, and that is not enough
    # once a slot is the thing build rows hang off.
    #
    # Scoped to `source = 1` (`game_files`) because the matrix side is not a set
    # of named ports at all: it repeats names by design, and a ship carries 32
    # rows called "Maneuvering Thruster". Measured before writing this --
    # unscoped, the index is impossible: 1,222 duplicate groups and 2,406 excess
    # rows, every one of them `ship_matrix`.
    #
    # So "the slot called X on this parent" is a well-defined thing for
    # game-files rows and meaningless for matrix ones, which is the same
    # asymmetry that keeps build rows off the matrix half.
    add_index :hardpoints, [:parent_type, :parent_id, :sc_name],
      unique: true, where: "source = 1",
      name: "index_hardpoints_on_parent_and_sc_name"
  end
end
