# frozen_string_literal: true

# What one build of the game says about a component, following the shape
# `equipment_builds` established.
#
# The field list is not invented here: `Component`'s paper_trail `only:` already
# names exactly the specs that move between builds, and its comment already
# anticipated "a row per build". This is that row.
#
# Unlike equipment, components are referenced -- hardpoints, model paints, model
# modules and missions all carry a `component_id`. Nothing about that changes: the
# identity row keeps its id and its associations, and the build rows sit beside it.
# Re-parenting the loadout tables is a later and separate question.
class CreateComponentBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :component_builds, id: :uuid do |t|
      # Cascade: a build says something about a component, and says nothing at
      # all once the component is gone.
      t.references :component, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      t.uuid :manufacturer_id
      t.string :name
      t.text :description
      t.string :size
      t.string :grade
      t.string :item_type
      t.integer :item_class
      t.string :component_class
      t.string :component_type
      t.string :component_sub_type
      t.string :category
      t.string :type_data
      t.string :durability
      t.string :power_connection
      t.string :heat_connection
      t.string :ammunition
      t.string :inventory_consumption
      t.integer :tracking_signal
      t.boolean :hidden, default: false

      t.timestamps
    end

    # One row per component per build. Re-loading the same build updates it in
    # place; a new build adds a row beside it.
    add_index :component_builds, [:component_id, :environment, :version],
      unique: true, name: "index_component_builds_on_component_and_build"

    # The filters a browsable catalogue needs, so narrowing to one build stays a
    # join rather than a scan. Every read names an environment and a version,
    # because that pair is what `ScData::Source` hands out.
    add_index :component_builds, [:environment, :version]
    add_index :component_builds, [:environment, :component_class]
    add_index :component_builds, [:environment, :item_type]
    add_index :component_builds, :manufacturer_id
  end
end
