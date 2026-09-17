# frozen_string_literal: true

# The recipe itself, as the game files nest it: an outer select of N named slots,
# each an inner select listing the materials that can fill it, and per slot the
# stats that filling it moves.
#
# Every inner select has exactly one option today -- all 4,289 slots across the
# 1,607 records in 4.10.1 -- so a single flat row per slot would lose nothing
# yet. It is kept as slots-and-options because the nesting is what lets the game
# say "any one of these three", which the UI already has a string for
# (`crafting_ui_ChooseOneMaterial`, "(Choose one material)").
#
# These rows hang off the *build* rather than off the blueprint. The recipe is a
# fact of one build the way the craft time is: live and ptu are loaded
# separately and a reader can be pointed at either, so a single global recipe
# would mean whichever tree loaded last supplied the costs for both -- live
# build facts rendered beside ptu materials.
#
# The loader replaces a build's rows wholesale on each run. Unlike a catalogue
# row, nothing points at a cost line -- no ledger entry, no loadout -- so there
# is nothing that has to keep resolving, and `prune_builds` takes the recipe
# with the build it belonged to.
class CreateBlueprintCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :blueprint_cost_slots, id: :uuid do |t|
      t.references :blueprint_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_blueprint_cost_slots_on_build"}

      # Order within the recipe. The export lists slots in a fixed order and the
      # page renders them that way, so it is stored rather than re-derived.
      t.integer :position, null: false

      # `debugName` -- "FRAME", "ARMOURED CARAPACE" -- normalised. The
      # `@crafting_ui_slotname_*` key beside it is what carries the label.
      t.string :sc_key
      t.string :name

      t.timestamps
    end

    add_index :blueprint_cost_slots, [:blueprint_build_id, :position],
      unique: true, name: "index_blueprint_cost_slots_on_build_and_position"

    create_table :blueprint_cost_options, id: :uuid do |t|
      t.references :blueprint_cost_slot, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_blueprint_cost_options_on_slot"}

      # Both kinds of cost resolve to a commodity, by two different routes: a
      # `CraftingCost_Resource` names a ResourceType GUID, a `CraftingCost_Item`
      # names a carryable entity, and both end at an `@items_commodities_*` key.
      # Nullable because a key the commodity catalogue does not carry must not
      # take the recipe down with it.
      t.references :commodity, type: :uuid, null: true,
        foreign_key: {on_delete: :nullify}

      # What the parser resolved, kept even when the join found nothing -- a
      # cost line that names a material we have no row for still has to say
      # which material.
      t.string :commodity_key

      # "resource" or "item". It is also the unit: a resource is priced in SCU,
      # an item in whole pieces.
      t.string :cost_type, null: false

      t.decimal :quantity, precision: 12, scale: 4
      t.integer :min_quality
      t.integer :position, null: false

      t.timestamps
    end

    add_index :blueprint_cost_options, [:blueprint_cost_slot_id, :position],
      unique: true, name: "index_blueprint_cost_options_on_slot_and_position"

    create_table :blueprint_cost_modifiers, id: :uuid do |t|
      t.references :blueprint_cost_slot, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {name: "index_blueprint_cost_modifiers_on_slot"}

      t.string :property_ref
      t.string :property_key
      t.string :name
      t.string :unit_format

      # `CraftingGameplayPropertyModifierValueRange_Linear` scales the stat,
      # `_LinearIntegerAdditive` adds to it -- 5,069 against 150 in 4.10.1 -- and
      # the two cannot be rendered with the same sentence.
      t.string :ramp, null: false

      t.integer :start_quality
      t.integer :end_quality
      t.decimal :modifier_at_start, precision: 12, scale: 4
      t.decimal :modifier_at_end, precision: 12, scale: 4
      t.integer :position, null: false

      t.timestamps
    end

    add_index :blueprint_cost_modifiers, [:blueprint_cost_slot_id, :position],
      unique: true, name: "index_blueprint_cost_modifiers_on_slot_and_position"
  end
end
