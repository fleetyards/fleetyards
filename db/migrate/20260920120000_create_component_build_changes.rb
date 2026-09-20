# frozen_string_literal: true

# What a patch changed about a component.
#
# `ScData::Source::BUILDS_RETAINED` keeps three builds per environment on live
# and two on ptu, and `ItemsLoader` prunes to that on every run -- so the diff
# against the patch before last is computable today and gone two patches from
# now. Storing the diff rather than relying on the builds is what makes a change
# log outlive the rows it was derived from, the same reason
# `model_build_changes` exists.
#
# `old_value` and `new_value` are text rather than the decimals the model table
# uses: a model fact is a number, while a component's are strings, enums and the
# scalar keys inside `type_data`.
class CreateComponentBuildChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :component_build_changes, id: :uuid do |t|
      # No index of its own: the unique composite below leads with
      # `component_id`, so a standalone one would only be a second copy of the
      # same prefix. `model_build_changes` carries none either.
      t.references :component, type: :uuid, null: false, index: false,
        foreign_key: {on_delete: :cascade}
      t.string :environment, null: false
      t.string :from_version, null: false
      t.string :to_version, null: false
      t.string :field, null: false
      t.text :old_value
      t.text :new_value
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    # Re-loading a build recomputes its diff, which replaces the rows for that
    # target version rather than appending a second copy of them.
    add_index :component_build_changes,
      %i[component_id environment to_version field],
      unique: true,
      name: "index_component_build_changes_on_component_and_field"

    add_index :component_build_changes, %i[environment to_version],
      name: "index_component_build_changes_on_build"

    add_index :component_build_changes, :recorded_at
  end
end
