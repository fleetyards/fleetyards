# frozen_string_literal: true

# A crafting recipe: what it makes, and -- through `blueprint_cost_slots` -- what
# it costs.
#
# `name` is denormalised from the crafted output on purpose. 1606 of the 1607
# records in 4.10.1 carry `blueprintName="@LOC_PLACEHOLDER"`, so a blueprint has
# no name of its own and the output supplies it. Reading it through the
# polymorphic association instead would put a three-way COALESCE across
# `components`, `equipment` and `commodities` into every list query, which is
# precisely what drops the index off a search or a sort.
class CreateBlueprints < ActiveRecord::Migration[8.1]
  def change
    create_table :blueprints, id: :uuid do |t|
      # The `__ref` of the CraftingBlueprintRecord. The record key is stable too,
      # but the ref is what every other record in the export refers to a
      # blueprint by -- the reward pools included.
      t.string :sc_ref, null: false
      t.string :sc_key, null: false
      t.string :slug, null: false

      t.string :name

      # Component, Equipment or Commodity. Deliberately not unique: three
      # outputs carry two blueprints each in 4.10.1 -- the 890 Jump and Polaris
      # S04 shields, two S01 quantum drives and two S02 powerplants -- and a
      # unique index would fail the load on what is near-certainly copy-paste in
      # the game data.
      t.references :craftable, type: :uuid, polymorphic: true, null: true, index: false

      # The category GUID cannot be labelled: `blueprintcategorydatabase` lists
      # 21 refs and none resolves to a record anywhere under Data/Libs. It is
      # stored because the two `basebuilding_interactables_itemfabricator_*`
      # whitelists key off it, so it says which machine can craft the thing.
      t.string :category_ref

      t.integer :craft_time
      t.integer :slot_count

      t.string :version

      t.timestamps
    end

    add_index :blueprints, :sc_ref, unique: true
    add_index :blueprints, :sc_key, unique: true
    add_index :blueprints, :slug, unique: true
    add_index :blueprints, [:craftable_type, :craftable_id]
    add_index :blueprints, :version
  end
end
