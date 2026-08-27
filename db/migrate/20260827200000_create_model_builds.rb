# frozen_string_literal: true

# What one build of the game says about a model, following the shape
# `equipment_builds`, `component_builds` and `commodity_builds` established.
#
# The columns are exactly the ones `ScData::Loader::ModelsLoader` writes, minus
# two groups:
#
# **Dimensions.** `sc_length`, `sc_beam` and `sc_height` stay off. A ship ships up
# to three unlabelled size sets -- flight, landed, and for some a deployed cargo
# grid or a combat configuration -- and no source says which one a number belongs
# to. A build row would enshrine one of them as *the* dimension, and there is no
# read path to layer it behind yet.
#
# **`in_game` and `production_status`.** The loader writes those through
# `apply_columns`, and `in_game` is already the thing a build row expresses: a
# parsed model file existing for this environment. Duplicating it here would give
# the same fact two homes.
class CreateModelBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :model_builds, id: :uuid do |t|
      # Cascade: a build says something about a model, and says nothing at all
      # once the model is gone.
      t.references :model, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      # Hull and mass.
      t.decimal :mass, precision: 15, scale: 2
      t.decimal :hull_health, precision: 15, scale: 2
      t.jsonb :hull_parts
      t.jsonb :hull_doors
      t.integer :weapon_pool_size
      t.jsonb :signature_cross_section
      t.boolean :ground, default: false

      t.decimal :personal_inventory, precision: 15, scale: 2

      # Serialized as YAML on Model, so the same type here or a round trip loses
      # the structure. This is the shape that broke the components loader: a
      # reader falls through to the column only on nil, and a raw YAML string is
      # not nil, so a caller expecting a hash got the string.
      t.string :cargo_holds
      t.string :quantum_fuel_tanks
      t.string :hydrogen_fuel_tanks
      t.string :external_fuel_tanks
      t.string :refuel_boom

      # Flight, off the ship's IFCS.
      t.decimal :scm_speed, precision: 15, scale: 2
      t.decimal :scm_speed_boosted, precision: 15, scale: 2
      t.decimal :reverse_speed_boosted, precision: 15, scale: 2
      t.decimal :max_speed, precision: 15, scale: 2
      t.decimal :pitch, precision: 15, scale: 2
      t.decimal :pitch_boosted, precision: 15, scale: 2
      t.decimal :yaw, precision: 15, scale: 2
      t.decimal :yaw_boosted, precision: 15, scale: 2
      t.decimal :roll, precision: 15, scale: 2
      t.decimal :roll_boosted, precision: 15, scale: 2

      # Ground vehicles only -- 27 of 215 models in game carry any of these.
      t.decimal :ground_max_speed, precision: 15, scale: 2
      t.decimal :ground_reverse_speed, precision: 15, scale: 2
      t.decimal :ground_acceleration, precision: 15, scale: 2
      t.decimal :ground_decceleration, precision: 15, scale: 2

      t.timestamps
    end

    # One row per model per build. Re-loading the same build updates it in place;
    # a new build adds a row beside it.
    add_index :model_builds, [:model_id, :environment, :version],
      unique: true, name: "index_model_builds_on_model_and_build"

    # Every read names an environment and a version, because that pair is what
    # `ScData::Source` hands out. No fact index yet: which of these the ship list
    # filters and sorts by is a question for the step that moves the filters,
    # and an index guessed now is one nothing measured.
    add_index :model_builds, [:environment, :version]
  end
end
