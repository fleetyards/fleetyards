# frozen_string_literal: true

# The first catalogue to separate what a thing *is* from what a build *says about
# it*. `equipment` keeps its identity -- the row a ledger entry points at, its
# sc_key, its slug, its uploaded image -- and everything the sc_data loader
# writes moves here.
#
# Equipment is the pilot because nothing references it: no child table carries an
# `equipment_id`, so the split is columns only.
#
# One row per item per build, so a patch can be diffed against the one before it
# and a bad load can be compared with what it replaced. Kept to the last few
# builds per environment rather than forever -- see BUILDS_RETAINED.
class CreateEquipmentBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_builds, id: :uuid do |t|
      # Cascade: a build says something about an item, and says nothing at all
      # once the item is gone.
      t.references :equipment, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      t.uuid :manufacturer_id
      t.string :name
      t.text :description
      t.string :equipment_type
      t.string :item_type
      t.string :sub_type
      t.string :weapon_class
      t.string :size
      t.string :grade
      t.integer :slot
      t.boolean :hidden, default: false
      t.decimal :rate_of_fire, precision: 15, scale: 2
      t.decimal :range, precision: 15, scale: 2
      t.decimal :storage, precision: 15, scale: 2
      t.decimal :damage_reduction, precision: 15, scale: 2
      t.string :temperature_rating
      t.decimal :radiation_protection, precision: 15, scale: 2
      t.decimal :radiation_scrub_rate, precision: 15, scale: 2
      t.decimal :g_force_tolerance, precision: 15, scale: 2
      t.integer :core_compatibility
      t.integer :backpack_compatibility
      t.decimal :volume, precision: 15, scale: 6
      t.jsonb :volume_dimensions

      t.timestamps
    end

    # One row per item per build. Re-loading the same build updates it in place;
    # a new build adds a row beside it.
    add_index :equipment_builds, [:equipment_id, :environment, :version],
      unique: true, name: "index_equipment_builds_on_equipment_and_build"

    # The filters a browsable catalogue needs, so narrowing to one build stays a
    # join rather than a scan. Every read names an environment and a version,
    # because that pair is what `ScData::Source` hands out.
    add_index :equipment_builds, [:environment, :version]
    add_index :equipment_builds, [:environment, :equipment_type]
    add_index :equipment_builds, [:environment, :item_type]
    add_index :equipment_builds, :manufacturer_id
  end
end
