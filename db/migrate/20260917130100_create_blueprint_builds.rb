# frozen_string_literal: true

# What one build of the game says about a blueprint, following the shape
# `commodity_builds`, `equipment_builds` and `component_builds` established.
#
# The crafted output is a fact rather than identity: a build can point a recipe
# somewhere else, and a blueprint whose output the export drops has to keep
# answering for the build that still named one.
class CreateBlueprintBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :blueprint_builds, id: :uuid do |t|
      t.references :blueprint, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      t.string :name
      t.references :craftable, type: :uuid, polymorphic: true, null: true, index: false
      t.string :category_ref
      t.integer :craft_time
      t.integer :slot_count

      t.timestamps
    end

    add_index :blueprint_builds, [:blueprint_id, :environment, :version],
      unique: true, name: "index_blueprint_builds_on_blueprint_and_build"

    add_index :blueprint_builds, [:environment, :version]
    add_index :blueprint_builds, [:environment, :name]
  end
end
