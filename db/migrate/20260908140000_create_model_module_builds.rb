# frozen_string_literal: true

# What one build of the game says about a model module, following the shape the
# other build tables established.
#
# `ModelModule` was the one catalogue the row-per-build work never covered, and
# the gap is not the two fields below -- it is **existence**. A module row is
# created by `ModulesImporter` from the RSI store data or by an admin, never by
# the loader, and it is shared by every source. So a module that only the PTU
# build describes shows up under live too, with `description` written by
# whichever load ran last and a loadout that resolves to nothing, because its
# slots carry `HardpointBuild` rows for ptu and not for live.
#
# With a row here, "does this build describe the module" is answerable, which is
# what `ModelModule.in_build` and `ScData::Source::BUILDS` need.
class CreateModelModuleBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :model_module_builds, id: :uuid do |t|
      # Cascade: a build says something about a module, and says nothing at all
      # once the module is gone.
      t.references :model_module, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      t.text :description

      # Serialized as YAML on the model, the same as on `model_modules`.
      t.string :cargo_holds

      t.timestamps
    end

    # One row per module per build. Re-loading the same build updates it in
    # place; a new build adds a row beside it.
    add_index :model_module_builds, [:model_module_id, :environment, :version],
      unique: true, name: "index_model_module_builds_on_module_and_build"

    add_index :model_module_builds, [:environment, :version]
  end
end
