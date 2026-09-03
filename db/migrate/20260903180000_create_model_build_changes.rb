# frozen_string_literal: true

# What a patch changed about a ship.
#
# `ModelBuild::BUILDS_RETAINED` keeps three builds per environment, so the diff
# against the patch before last is computable today and pruned away two patches
# from now. Storing the diff rather than relying on the builds is what makes a
# change log outlive the rows it was derived from.
class CreateModelBuildChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :model_build_changes, id: :uuid do |t|
      t.references :model, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :environment, null: false
      t.string :from_version, null: false
      t.string :to_version, null: false
      t.string :field, null: false
      t.decimal :old_value, precision: 15, scale: 2
      t.decimal :new_value, precision: 15, scale: 2
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    # Re-loading a build recomputes its diff, which replaces the rows for that
    # target version rather than appending a second copy of them.
    add_index :model_build_changes,
      %i[model_id environment to_version field],
      unique: true,
      name: "index_model_build_changes_on_model_and_field"

    add_index :model_build_changes, %i[environment to_version],
      name: "index_model_build_changes_on_build"

    add_index :model_build_changes, :recorded_at
  end
end
